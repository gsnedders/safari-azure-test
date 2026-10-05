#!/bin/bash
# Find the launchd job that (transitively) owns this process, and report its
# plist path and SessionCreate setting as launchd actually loaded it.
# Walks up the process tree from $$ until a pid matches a `launchctl list` row.

pid=$$
label=
while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
  label="$(launchctl list | awk -v p="$pid" '$1 == p { print $3 }')"
  [ -n "$label" ] && break
  pid="$(ps -o ppid= -p "$pid" | tr -d ' ')"
done

if [ -z "$label" ]; then
  echo "no owning launchd job found in $(launchctl managername)'s list (not run from a launchd job?)"
  exit 0
fi

echo "owning launchd job: $label (pid $pid)"

domain="gui/$(id -u)"
launchctl print "$domain/$label" 2>&1 | grep -E '^\s*(path|state|pid|program|type) ' | sed 's/^/  /'

path="$(launchctl print "$domain/$label" 2>/dev/null | sed -n 's/^[[:space:]]*path = //p' | head -1)"
if [ -n "$path" ] && [ -f "$path" ]; then
  if value="$(plutil -extract SessionCreate raw -o - "$path" 2>/dev/null)"; then
    echo "  SessionCreate in $path: $value"
  else
    echo "  SessionCreate in $path: (key absent)"
  fi
else
  echo "  plist path not found via launchctl print (got: '${path:-}')"
fi
