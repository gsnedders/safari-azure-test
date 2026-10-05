#!/bin/bash
# Payload run inside the launchd job by run.sh. Uses a throwaway keychain item
# (same approach as ../test.sh) so nothing real is touched.

echo "== context"
id
launchctl managername
date '+%Y-%m-%d %H:%M:%S'

echo "== keychain state"
security list-keychains -d user
security default-keychain
security show-keychain-info ~/Library/Keychains/login.keychain-db

echo "== keychain round-trip"
security add-generic-password -a "sc-$$" -s sc.test -w v -U ~/Library/Keychains/login.keychain-db
echo "add: $?"
security find-generic-password -a "sc-$$" -s sc.test -w ~/Library/Keychains/login.keychain-db
echo "find: $?"
security delete-generic-password -a "sc-$$" -s sc.test ~/Library/Keychains/login.keychain-db
echo "delete: $?"

echo "== safaridriver right"
security authorize com.apple.safaridriver.allow
echo "safaridriver right: $?"
