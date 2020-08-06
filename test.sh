#!/bin/bash

set -x

log stream --info --debug --predicate '(subsystem == "com.apple.TCC")' &

cat ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
HOMEBREW_NO_AUTO_UPDATE=1 brew cask install safari-technology-preview.rb
# chmod +x allowremote
# ./allowremote
sudo "/Applications/Safari Technology Preview.app/Contents/MacOS/safaridriver" --enable
cat ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
