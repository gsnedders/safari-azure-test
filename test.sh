#!/bin/bash

set -x

date '+%Y-%m-%d %H:%M:%S' > /Users/runner/test-start-time

DEBUG_SUBSYSTEMS=(
  com.apple.Authorization
  com.apple.WebDriver
  com.apple.WebDriver.HTTPService
  com.apple.TCC
  com.apple.sandbox
  com.apple.SafariShared
  com.apple.SafariTechnologyPreview
  com.apple.WebInspector
)

for subsystem in "${DEBUG_SUBSYSTEMS[@]}"; do
  sudo log config --mode level:debug,persist:debug --subsystem "$subsystem"
done

id
dseditgroup -o checkmember -m "$(whoami)" _webdeveloper || true
dseditgroup -o checkmember -m "$(whoami)" admin || true
sudo launchctl procinfo $$ || true
launchctl print "gui/$(id -u)" || true
security authorize com.apple.safaridriver.allow
echo "non-interactive authorize exit: $?"

security list-keychains -d user
sleep 5

# Deliberately not `security unlock-keychain`: that would force it open and mask
# the actual question, whether the login keychain is already unlocked in this
# ambient session.
security add-generic-password -a "test-$$" -s com.apple.safaridriver.test -w "test-value" -U ~/Library/Keychains/login.keychain-db
sleep 5

security find-generic-password -a "test-$$" -s com.apple.safaridriver.test -w ~/Library/Keychains/login.keychain-db
sleep 5

security delete-generic-password -a "test-$$" -s com.apple.safaridriver.test ~/Library/Keychains/login.keychain-db
sleep 5

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

sudo "/Applications/Safari Technology Preview.app/Contents/MacOS/safaridriver" --enable
sleep 5

ls -lR ~/Library/WebDriver
sleep 5

plutil -p ~/Library/WebDriver/com.apple.Safari.plist
sleep 5

plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
sleep 5

sudo /usr/bin/safaridriver --enable
sleep 5

ls -lR ~/Library/WebDriver
sleep 5

plutil -p ~/Library/WebDriver/com.apple.Safari.plist
sleep 5

plutil -p ~/Library/WebDriver/com.apple.SafariTechnologyPreview.plist
sleep 5

try_webdriver_session() {
  local driver_binary="$1"
  local port="$2"
  local label="$3"

  "$driver_binary" -p "$port" > "/tmp/safaridriver-$label.log" 2>&1 &
  local driver_pid=$!
  sleep 5

  local status
  status=$(curl -s -o "/tmp/session-$label.json" -w '%{http_code}' -X POST "http://localhost:$port/session" \
    -H 'Content-Type: application/json' \
    -d '{"capabilities":{"alwaysMatch":{"browserName":"safari"}}}')
  echo "$label session create HTTP status: $status"
  cat "/tmp/session-$label.json"
  sleep 5

  local session_id
  session_id=$(python3 -c "import json; print(json.load(open('/tmp/session-$label.json')).get('value',{}).get('sessionId',''))" 2>/dev/null || true)
  if [ -n "$session_id" ]; then
    curl -s -X DELETE "http://localhost:$port/session/$session_id"
    echo "Deleted $label session $session_id"
  fi
  sleep 5

  cat "/tmp/safaridriver-$label.log"
  kill "$driver_pid" 2>/dev/null || true
  sleep 5
}

try_webdriver_session /usr/bin/safaridriver 4444 safari
try_webdriver_session "/Applications/Safari Technology Preview.app/Contents/MacOS/safaridriver" 4445 stp

for subsystem in "${DEBUG_SUBSYSTEMS[@]}"; do
  sudo log config --reset --subsystem "$subsystem"
done
