
import html5lib
import logging
import os
import platform
import re
import shutil
import subprocess
import tempfile

from packaging.specifiers import SpecifierSet
from requests import get
from urllib.parse import urlsplit

logger = logging.getLogger("download")


def get_download_filename(resp, default=None):
    """Get the filename from a requests.Response, or default"""
    filename = None

    content_disposition = resp.headers.get("content-disposition")
    if content_disposition:
        filenames = re.findall("filename=(.+)", content_disposition)
        if filenames:
            filename = filenames[0]

    if not filename:
        filename = urlsplit(resp.url).path.rsplit("/", 1)[1]

    return filename or default


def _find_downloads():
    def text_content(e, __output=None):
        # this doesn't use etree.tostring so that we can add spaces for p and br
        if __output is None:
            __output = []

        if e.tag == "p":
            __output.append("\n\n")

        if e.tag == "br":
            __output.append("\n")

        if e.text is not None:
            __output.append(e.text)

        for child in e:
            text_content(child, __output)
            if child.tail is not None:
                __output.append(child.tail)

        return "".join(__output)

    logger.info("Finding STP download URLs")
    resp = get("https://developer.apple.com/safari/download/")

    doc = html5lib.parse(
        resp.content,
        "etree",
        namespaceHTMLElements=False,
        transport_encoding=resp.encoding,
    )
    ascii_ws = re.compile(r"[\x09\x0A\x0C\x0D\x20]+")

    downloads = []
    for candidate in doc.iterfind(".//li[@class]"):
        class_names = set(ascii_ws.split(candidate.attrib["class"]))
        if {"download", "dmg", "zip"} & class_names:
            downloads.append(candidate)

    # Note we use \s throughout for space as we don't care what form the whitespace takes
    stp_link_text = re.compile(
        r"^\s*Safari\s+Technology\s+Preview\s+(?:[0-9]+\s+)?for\s+macOS"
    )
    requirement = re.compile(
        r"""(?x)  # (extended regexp syntax for comments)
        ^\s*Requires\s+macOS\s+  # Starting with the magic string
        ([0-9]+(?:\.[0-9]+)*)  # A macOS version number of numbers and dots
        (?:\s+beta(?:\s+[0-9]+)?)?  # Optionally a beta, itself optionally with a number (no dots!)
        (?:\s+or\s+later)?  # Optionally an 'or later'
        \.?\s*$  # Optionally ending with a literal dot
        """
    )

    stp_downloads = []
    for download in downloads:
        for link in download.iterfind(".//a[@href]"):
            if stp_link_text.search(text_content(link)):
                break
            else:
                logger.debug("non-matching anchor: " + text_content(link))
        else:
            continue

        for el in download.iter():
            # avoid assuming any given element here, just assume it is a single element
            m = requirement.search(text_content(el))
            if m:
                version = m.group(1)

                # This assumes the current macOS numbering, whereby X.Y is compatible
                # with X.(Y+1), e.g. 12.4 is compatible with 12.3, but 13.0 isn't
                # compatible with 12.3.
                if version.count(".") >= (2 if version.startswith("10.") else 1):
                    spec = SpecifierSet(f"~={version}")
                else:
                    spec = SpecifierSet(f"=={version}.*")

                stp_downloads.append((spec, link.attrib["href"].strip()))
                break
        else:
            logger.debug("Found a link but no requirement: " + text_content(download))

    if stp_downloads:
        logger.info(
            "Found STP URLs for macOS " + ", ".join(str(dl[0]) for dl in stp_downloads)
        )
    else:
        logger.warning("Did not find any STP URLs")

    return stp_downloads


def _download_image(downloads, dest, system_version=None):
    if system_version is None:
        system_version, _, _ = platform.mac_ver()

    chosen_url = None
    for version_spec, url in downloads:
        if system_version in version_spec:
            logger.debug(f"Will download Safari for {version_spec}")
            chosen_url = url
            break

    if chosen_url is None:
        raise ValueError(f"no download for {system_version}")

    logger.info(f"Downloading Safari from {chosen_url}")
    resp = get(chosen_url)

    filename = get_download_filename(resp, "SafariTechnologyPreview.dmg")
    installer_path = os.path.join(dest, filename)
    with open(installer_path, "wb") as f:
        f.write(resp.content)

    return installer_path


def _download_extract(image_path, dest, rename=None):
    with tempfile.TemporaryDirectory() as tmpdir:
        logger.debug(f"Mounting {image_path}")
        r = subprocess.run(
            [
                "hdiutil",
                "attach",
                "-readonly",
                "-mountpoint",
                tmpdir,
                "-nobrowse",
                "-verify",
                "-noignorebadchecksums",
                "-autofsck",
                image_path,
            ],
            encoding="utf-8",
            capture_output=True,
            check=True,
        )

        mountpoint = None
        for line in r.stdout.splitlines():
            if not line.startswith("/dev/"):
                continue

            _, _, mountpoint = line.split("\t", 2)
            if mountpoint:
                break

        if mountpoint is None:
            raise ValueError("no volume mounted from image")

        pkgs = [p for p in os.listdir(mountpoint) if p.endswith((".pkg", ".mpkg"))]
        if len(pkgs) != 1:
            raise ValueError(
                f"Expected a single .pkg/.mpkg, found {len(pkgs)}: {', '.join(pkgs)}"
            )

        source_path = os.path.join(mountpoint, pkgs[0])
        _, ext = os.path.splitext(pkgs[0])
        dest_path = os.path.join(
            dest, (rename + ext) if rename is not None else pkgs[0]
        )

        logger.debug(f"Copying {source_path} to {dest_path}")
        shutil.copy2(
            source_path,
            dest_path,
        )

        logger.debug(f"Unmounting {mountpoint}")
        subprocess.run(
            ["hdiutil", "detach", mountpoint],
            encoding="utf-8",
            capture_output=True,
            check=True,
        )

    return dest_path


def download(dest=None, channel="preview", rename=None, system_version=None):
    if channel != "preview":
        raise ValueError(f"can only install 'preview', not '{channel}'")

    if dest is None:
        dest = "."

    stp_downloads = _find_downloads()

    with tempfile.TemporaryDirectory() as tmpdir:
        image_path = _download_image(stp_downloads, tmpdir, system_version)
        return _download_extract(image_path, dest, rename)


if __name__ == "__main__":
    print(download(rename="STP"))
