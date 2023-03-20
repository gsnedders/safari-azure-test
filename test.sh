#!/bin/bash

set -x

sudo log config --mode "level:debug,persist:debug"
log stream --info --debug --predicate '(subsystem == "com.apple.TCC")' &

ls -lR ~/Library/WebDriver
sleep 5

plutil -p ~/Library/WebDriver/com.apple.Safari.plist
sleep 5

plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
sleep 5

python3 -m pip install html5lib packaging requests
python3 download.py
sudo installer -pkg STP.pkg -target LocalSystem
sleep 5

sudo /Applications/Safari\ Technology\ Preview.app/Contents/MacOS/safaridriver --enable
sleep 5


ls -lR ~/Library/WebDriver
sleep 5

plutil -p ~/Library/WebDriver/com.apple.Safari.plist
sleep 5

plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
sleep 5

pkill log
sleep 5

sudo log config --mode "level:default,persist:default"
