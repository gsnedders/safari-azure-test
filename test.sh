#!/bin/bash

set -x

sudo log config --mode "level:debug,persist:debug"
log stream --info --debug --predicate '(subsystem == "com.apple.TCC")' &

ls -lR ~/Library/WebDriver

python3 -m pip install html5lib packaging requests
python3 download.py
sudo installer -pkg STP.pkg -target LocalSystem
sleep 10

sudo /Applications/Safari\ Technology\ Preview.app/Contents/MacOS/safaridriver --enable
sleep 10

ls -lR ~/Library/WebDriver
plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
sleep 10

pkill log

sleep 10
sudo log config --mode "level:default,persist:default"
