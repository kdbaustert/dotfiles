#!/usr/bin/env bash
#
# Mac App Store apps. bash, not zsh — see the note in composer.sh: the list
# below is a bash array, and keeping one shell across every script in setup/
# means one set of guards rather than four dialects.
#
# mas needs you signed in to the App Store; it cannot do that itself. If the
# installs below all fail, check Settings → Apple Account first.
set -uo pipefail

if ! command -v mas >/dev/null 2>&1; then
  echo "mas not found — skipping (install it via the Brewfile first)." >&2
  exit 0
fi

# "<app-id>:<name>" — the id is what mas takes, the name keeps this readable.
apps=(
  "497799835:Xcode"
  "975937182:Fantastical"
  "1507782672:Pixea"
  "1355679052:Dropover"
  "1456386228:Clockology"
  "1436522307:Transmit 5"
  "937984704:Amphetamine"
  "1176895641:Spark"
  "1212019923:Antivirus Zap"
)

# `mas install` exits non-zero on an already-installed app, so check first —
# install.sh is meant to be safely re-runnable. `mas list` prints "<id> <name>",
# hence anchoring the match to the id followed by whitespace.
installed="$(mas list 2>/dev/null)"

for app in "${apps[@]}"; do
  id="${app%%:*}"
  name="${app#*:}"
  if printf '%s\n' "$installed" | grep -qE "^${id}[[:space:]]"; then
    echo "Mac App Store app already installed: $name"
  else
    mas install "$id" || echo "Failed to install $name ($id)." >&2
  fi
done
