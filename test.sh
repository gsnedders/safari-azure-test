#!/bin/bash

set -e

cat ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
HOMEBREW_NO_AUTO_UPDATE=1 brew cask install safari-technology-preview.rb
chmod +x allowremote
./allowremote
sudo "/Applications/Safari Technology Preview.app/Contents/MacOS/safaridriver" --enable
cat ~/Library/WebDriver/com.apple.SafariTechnologyPreview12.plist
