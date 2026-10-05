#!/bin/bash
# Run sc-test.sh once as a launchd job, in a chosen domain, with or without
# SessionCreate=true, and show its output plus the matching authd log lines.
#
#   [STATE=label] ./run.sh [gui|user|system] true|default
#
#   gui      LaunchAgent in gui/<uid>   (needs you logged in at the console)  [default]
#   user     LaunchAgent in user/<uid>  (works over SSH with no GUI login)
#   system   LaunchDaemon run as you via UserName (uses sudo)
#
#   true     adds <key>SessionCreate</key><true/> (the GitHub Actions runner default)
#   default  no SessionCreate key (control)
#
# STATE is a free-form label for the machine state being tested (e.g.
# gui-login, ssh-only, loginwindow). The full output is also saved to
# results/<STATE>-<domain>-<mode>.txt next to this script.

set -u

case $# in
  1) domain_kind=gui; mode="$1" ;;
  2) domain_kind="$1"; mode="$2" ;;
  *) echo "usage: [STATE=label] $0 [gui|user|system] true|default" >&2; exit 2 ;;
esac

case "$domain_kind" in
  gui)    domain="gui/$(id -u)";  sudo_cmd=() ;;
  user)   domain="user/$(id -u)"; sudo_cmd=() ;;
  system) domain="system";        sudo_cmd=(sudo) ;;
  *) echo "unknown domain '$domain_kind' (gui|user|system)" >&2; exit 2 ;;
esac

case "$mode" in
  true)    session_create='<key>SessionCreate</key><true/>' ;;
  default) session_create='' ;;
  *) echo "unknown mode '$mode' (true|default)" >&2; exit 2 ;;
esac

dir="$(cd "$(dirname "$0")" && pwd)"
state="${STATE:-unlabelled}"
mkdir -p "$dir/results"
exec > >(tee "$dir/results/$state-$domain_kind-$mode.txt") 2>&1

label="test.sessioncreate.$domain_kind.$mode"
plist="/tmp/$label.plist"
out="/tmp/sc-test-$domain_kind-$mode.out"

user_key=''
if [ "$domain_kind" = system ]; then
  user_key="<key>UserName</key><string>$(id -un)</string>"
fi

echo "===== state: $state | domain: $domain | SessionCreate: $mode ====="
echo "console user: $(stat -f%Su /dev/console)"
echo "this shell:   $(launchctl managername 2>&1)"
date '+%Y-%m-%d %H:%M:%S'
echo

cp "$dir/sc-test.sh" /tmp/sc-test.sh
chmod 755 /tmp/sc-test.sh
"${sudo_cmd[@]}" rm -f "$out"

cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>/tmp/sc-test.sh</string></array>
  <key>RunAtLoad</key><true/>
  $user_key
  $session_create
  <key>StandardOutPath</key><string>$out</string>
  <key>StandardErrorPath</key><string>$out</string>
</dict></plist>
EOF

if [ "$domain_kind" = system ]; then
  sudo chown root:wheel "$plist"
  sudo chmod 644 "$plist"
fi

"${sudo_cmd[@]}" launchctl bootout "$domain/$label" 2>/dev/null
start="$(date '+%Y-%m-%d %H:%M:%S')"
"${sudo_cmd[@]}" launchctl bootstrap "$domain" "$plist" || exit 1

# Wait for the payload's last line (up to ~60s; a keychain prompt would stall it).
for _ in $(seq 1 60); do
  grep -q 'safaridriver right:' "$out" 2>/dev/null && break
  sleep 1
done

"${sudo_cmd[@]}" launchctl bootout "$domain/$label" 2>/dev/null

echo "===== job output ====="
cat "$out" 2>/dev/null || echo "(no output: job never ran or stalled)"

echo
echo "===== authd (since $start) ====="
/usr/bin/log show --start "$start" --info --debug \
  --predicate 'process == "authd"' 2>&1 \
  | grep -E 'session owner|safaridriver|-60007|does (NOT )?satisfy' || echo "(nothing matched; log show may need sudo)"
