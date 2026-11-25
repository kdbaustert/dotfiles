---
paths:
  - "**/Info.plist"
  - "**/Package.swift"
  - "**/release.sh"
  - "**/appcast*.xml"
  - "**/.github/workflows/release*.yml"
  - "**/*Updater*.swift"
---

# Sparkle signing keys

Every app that ships Sparkle updates gets its own EdDSA key pair, stored under
its own keychain account. `generate_keys --help` says one key is enough for
any number of apps. Ignore that here: a shared key means one leak lets someone
sign updates for every app, and replacing it means a new `SUPublicEDKey` in
all of them at once. This covers apps Kenny ships, not a fork's upstream key
(`ghostty`).

## Adding Sparkle to an app

1. Name the keychain account after the app's SwiftPM product, e.g. `DockPlus`,
   and create the key with `generate_keys --account <App>`.
2. Put the public key it prints in `SUPublicEDKey` in that app's
   `Resources/Info.plist`.
3. Check no other app has it:
   `rg -l -F '<public key>' ~/Developer -g 'Info.plist'` lists one file.
4. For CI, give Kenny the commands to run with `!` rather than running them:
   `generate_keys --account <App> -x <file>`, then
   `gh secret set SPARKLE_PRIVATE_KEY < <file>` in that app's repo, then a
   backup and `rm <file>`. The private key never passes through the session,
   and the secret is per repository, never an org or shared one.

The bundled tools live in `.build/artifacts/sparkle/Sparkle/bin/` after
`swift package resolve`.

## Every signing call names its key

- Locally, `generate_appcast`, `sign_update` and `generate_keys -p` always
  take `--account <App>`. A bare call reads the default `ed25519` account,
  which already holds one app's key, and signs with it without complaint.
  Every installed copy of the other app then rejects the update, and nothing
  on the release side reports it.
- In CI they take `--ed-key-file` instead. The existing `release.sh` scripts
  do this with `APPCAST_ARGS=(--account <App>)`, swapped for `--ed-key-file`
  when `SPARKLE_KEY_FILE` is set. Copy that.
- A release workflow imports the secret and compares `generate_keys -p` with
  `SUPublicEDKey` before signing anything. Copy the "Import the Sparkle signing
  key" step from a sibling app. Its bare `-f` and `-p` are fine there, because
  the runner's keychain is empty and thrown away.

## Changing a shipped app's key

Don't, without asking. Installed copies trust only the key they shipped with,
so a new `SUPublicEDKey` strands them on their current version. Sparkle lets
the EdDSA key change only when the update keeps the same Developer ID
signature, and these apps ship ad-hoc signed. Moving an app off the default
account to a named one is different and safe: export it with `-x`, import it
with `--account <App> -f`, and the public key stays the same. Point out an app
still on the default account; don't move it unasked.
