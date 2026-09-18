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
  eslint
  eslint-config-prettier
  eslint-plugin-prettier
  eslint-plugin-vue
  firebase-tools
  gitignore.cli
  # The PHP language server. Also in both editors' Mason lists
  # (.config/nvim/lua/plugins/lsp.lua, .config/lvim/config.lua), which is where
  # servers normally come from here — this copy is the one on PATH, for
  # anything that expects to find intelephense itself rather than ask an editor
  # to fetch it. Two installs, so check both when the version matters.
  intelephense
  ntl
  prettier
  @prettier/plugin-php
  prettier-init
  stylelint
  svgo
  # Held at 6 on purpose: npm's `latest` is 7.x, the native rewrite. Without the
  # pin this list silently upgrades across that boundary on the next run, since
  # `npm install -g` doubles as the update path. Drop the `@6` to follow latest.
  typescript@6
  # The standalone TypeScript language server, for anything that expects it on
  # PATH. Same two-installs caveat as intelephense above: the editors get their
  # own copy through Mason as `ts_ls` (nvim) and `tsserver` (lvim).
  typescript-language-server
)

# Idempotent as-is: `npm install -g` on an installed package is an upgrade-or-
# no-op, so this doubles as the update path.
npm install -g "${npm[@]}"
