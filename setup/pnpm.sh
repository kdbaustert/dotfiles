#!/usr/bin/env bash
#
# Global JS packages, installed with pnpm. bash, not sh — see the note in
# composer.sh: the list below is a bash array and would be a syntax error under
# a real POSIX sh.
#
# WHY PNPM AND NOT NPM. This was setup/npm.sh running `npm install -g` until
# the two were compared on a working machine: every package here already
# existed under pnpm (~/Library/pnpm), npm's own global prefix held only
# neovim, npm and tree-sitter-cli, and every binary that matters — tsc,
# prettier, eslint, intelephense — resolved to ~/Library/pnpm/bin. So the
# script had been installing a second, shadowed copy of each package into a
# prefix nothing on PATH reads. The pnpm globals are the real ones; .zprofile
# puts $PNPM_HOME/bin on PATH and .claude/CLAUDE.md already described Prettier
# as a pnpm global.
set -uo pipefail

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm not found — skipping. Install it first (Homebrew on macOS, pkglist on Arch)." >&2
  exit 0
fi

# pnpm refuses to install globally without a global bin directory and will not
# guess one: no PNPM_HOME means ERR_PNPM_NO_GLOBAL_BIN_DIR and nothing
# installed. .zprofile exports it, but .zprofile is a LOGIN file and this
# script is a bash child of install.sh — on the first run of a fresh machine
# the file has only just been symlinked and no shell has read it yet, so the
# variable is simply absent (measured: `env -i bash -c` sees nothing). Hence
# the same two values, derived the same way, rather than a dependency on
# having logged in once already. Exported, not just set, because pnpm reads it
# from the environment.
if [ -z "${PNPM_HOME:-}" ]; then
  case "$OSTYPE" in
    darwin*) export PNPM_HOME="$HOME/Library/pnpm" ;;
    *)       export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm" ;;
  esac
fi
# pnpm also wants its bin dir on PATH for the run itself, and on a fresh
# machine it is not there yet for the same reason.
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH

pkgs=(
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
  # Held at 6 on purpose: pnpm's `latest` is 7.x, the native rewrite. Without
  # the pin this list silently upgrades across that boundary on the next run,
  # since this script doubles as the update path. Drop the `@6` to follow latest.
  typescript@6
  # The standalone TypeScript language server, for anything that expects it on
  # PATH. Same two-installs caveat as intelephense above: the editors get their
  # own copy through Mason as `ts_ls` (nvim) and `tsserver` (lvim).
  typescript-language-server
)

# Idempotent as-is: `pnpm add -g` on an installed package is an
# upgrade-or-no-op, so this doubles as the update path.
pnpm add -g "${pkgs[@]}"
