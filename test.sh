#!/bin/bash

set -x

date '+%Y-%m-%d %H:%M:%S' > /Users/runner/test-start-time

id
dseditgroup -o checkmember -m "$(whoami)" _webdeveloper || true
dseditgroup -o checkmember -m "$(whoami)" admin || true
sudo launchctl procinfo $$ || true
launchctl print "gui/$(id -u)" || true
security authorize com.apple.safaridriver.allow
echo "non-interactive authorize exit: $?"

sudo log config --mode level:debug,persist:debug --subsystem com.apple.Authorization
sudo log config --mode level:debug,persist:debug --subsystem com.apple.WebDriver
sudo log config --mode level:debug,persist:debug --subsystem com.apple.WebDriver.HTTPService
sudo log config --mode level:debug,persist:debug --subsystem com.apple.TCC
sudo log config --mode level:debug,persist:debug --subsystem com.apple.sandbox
sudo log config --mode level:debug,persist:debug --subsystem com.apple.SafariShared
sudo log config --mode level:debug,persist:debug --subsystem com.apple.SafariTechnologyPreview

ls -lR ~/Library/WebDriver
sleep 5

plutil -p ~/Library/WebDriver/com.apple.Safari.plist
sleep 5

plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
sleep 5

rm -rf ~/Library/WebDriver
sleep 5

ls -lR ~/Library/WebDriver
sleep 5

plutil -p ~/Library/WebDriver/com.apple.Safari.plist
sleep 5

plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
sleep 5

python3 -m venv /tmp/venv
source /tmp/venv/bin/activate
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

sudo safaridriver --enable
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
