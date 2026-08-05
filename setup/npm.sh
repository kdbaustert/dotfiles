#!/usr/bin/env bash
#
# Global npm packages. bash, not sh — see the note in composer.sh: the list
# below is a bash array and would be a syntax error under a real POSIX sh.
set -uo pipefail

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found — skipping." >&2
  exit 0
fi

npm=(
  @vue/cli
  eslint
  prettier
  @prettier/plugin-php
  eslint-plugin-prettier
  eslint-config-prettier
  eslint-plugin-vue
  typescript
  #generator-code
  #yo
  #fkill-cli
  #vsce
  #cli-error-notifier
  #npm-check
  stylelint
  #alfred-npms
  firebase-tools
  ntl
  prettier-init
  #generator-alfred
  #alfred-fkill
  #browser-sync
  #gulp-cli
  #gatsby-cli
  svgo
  #npm-check-updates
  #blade-formatter
  gitignore.cli
  #@phartenfeller/alfred-vscode-workspaces
)

npm install -g "${npm[@]}"
