#!/usr/bin/env bash
#
# Global npm packages. bash, not sh — see the note in composer.sh: the list
# below is a bash array and would be a syntax error under a real POSIX sh.
set -uo pipefail

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found — skipping (node ships it; install node via the Brewfile first)." >&2
  exit 0
fi

npm=(
  @vue/cli
  eslint
  eslint-config-prettier
  eslint-plugin-prettier
  eslint-plugin-vue
  firebase-tools
  gitignore.cli
  ntl
  prettier
  @prettier/plugin-php
  prettier-init
  stylelint
  svgo
  typescript
)

# Idempotent as-is: `npm install -g` on an installed package is an upgrade-or-
# no-op, so this doubles as the update path.
npm install -g "${npm[@]}"
