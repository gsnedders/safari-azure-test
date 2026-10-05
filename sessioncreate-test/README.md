# SessionCreate experiment matrix

Question: is there any configuration where `SessionCreate=true` helps? (The
GitHub Actions runner sets it for login-keychain access, per
actions/runner#350/#847.) We already know that with a live GUI session it
breaks both the login keychain and the `com.apple.safaridriver.allow` right.

`run.sh` runs `sc-test.sh` once as a launchd job and records: keychain lock
state and add/find/delete, whether the safaridriver right is granted, and
authd's view of the session owner. Output also lands in `results/`.

Usage: `STATE=<label> ./run.sh [gui|user|system] true|default`

## Rows to fill in

Run each row with both `true` and `default`. Set `STATE` to the machine state.

| STATE | Machine state | Domains to run | Notes |
|---|---|---|---|
| `gui-login` | Logged in at the console, keychain unlocked | `gui`, `user`, `system` | `gui` done 2026-10-05: true breaks both, default works |
| `ssh-only` | Autologin off, at the login window, you SSH in | `user`, `system` | `gui` won't exist; the likely #350 scenario |
| `gui-locked` | Logged in at the console, screen locked / keychain locked | `gui`, `user` | Separates "no session" from "keychain locked" |

For `ssh-only`: reboot with autologin off, don't log in at the console, SSH in.
In that state the login keychain is probably locked and unreachable, so
`default` failing there is expected, and the interesting question is whether
`true` is any better.

## Reading results

- Does the keychain round-trip ever work under `true` when it fails under
  `default`? That would be the case #350 describes.
- Does authd's session owner differ (`-3` invalid versus a real uid)?
- Compare the `safaridriver right:` exit code across rows.

If `true` never beats `default` on the keychain in any row, #350's rationale
doesn't hold on current macOS, and the GitHub issue can say so.
