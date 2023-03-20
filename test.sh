#!/bin/bash

set -x

log stream --info --debug --predicate '(subsystem == "com.apple.TCC")' &

ls -lR ~/Library/WebDriver

python -m pip install html5lib packaging requests
python download.py
sudo installer -pkg STP.pkg -target LocalSystem
sudo /Applications/Safari\ Technology\ Preview.app/Contents/MacOS/safaridriver --enable

ls -lR ~/Library/WebDriver
plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist

pkill log
