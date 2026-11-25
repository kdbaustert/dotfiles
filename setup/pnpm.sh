#!/usr/bin/env bash
#
# Global JS packages, installed with pnpm. bash, not sh (see the note in
# composer.sh): the list below is a bash array and would be a syntax error under
# a real POSIX sh.
#
# WHY PNPM AND NOT NPM. Installing with `npm install -g` would put a second,
# shadowed copy of each package into a prefix nothing on PATH reads. On a
# working machine every package here already lives under pnpm (~/Library/pnpm),
# npm's own global prefix holds only neovim and npm, and every
# binary that matters (tsc, prettier, eslint, intelephense) resolves to
# ~/Library/pnpm/bin. The pnpm globals are the real ones; .zprofile puts
# $PNPM_HOME/bin on PATH and .claude/CLAUDE.md describes Prettier as a pnpm
# global.
set -uo pipefail

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm not found — skipping. Install it first (brew install pnpm)." >&2
  exit 0
fi

# pnpm refuses to install globally without a global bin directory and will not
# guess one: no PNPM_HOME means ERR_PNPM_NO_GLOBAL_BIN_DIR and nothing
# installed. .zprofile exports it, but .zprofile is a LOGIN file and this
# script is a bash child of install.sh. On the first run of a fresh machine
# the file has only just been symlinked and no shell has read it yet, so the
# variable is simply absent (measured: `env -i bash -c` sees nothing). So the
# same two values are derived the same way here, rather than depending on
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
  # The binary only, like prettier below. The packages ~/eslint.config.mjs
  # imports live in .config/eslint, for the same reason.
  eslint
  firebase-tools
  gitignore.cli
  # The PHP language server. Also in both editors' Mason lists
  # (.config/nvim/lua/plugins/lsp.lua, .config/lvim/config.lua), which is where
  # servers normally come from here. This copy is the one on PATH, for
  # anything that expects to find intelephense itself rather than ask an editor
  # to fetch it. Two installs, so check both when the version matters.
  intelephense
  ntl
  # The binary only. Its PHP plugin is not a global: Prettier can't import
  # from another global's isolated directory, so the plugin lives in
  # .config/prettier and is installed at the end of this script.
  prettier
  prettier-init
  stylelint
  svgo
  # Held at 6 on purpose: pnpm's `latest` is 7.x, the native rewrite. Without
  # the pin this list would upgrade across that boundary on the next run,
  # since this script doubles as the update path. Drop the `@6` to follow latest.
  typescript@6
  # The standalone TypeScript language server, for anything that expects it on
  # PATH. Same two-installs caveat as intelephense above: the editors get their
  # own copy through Mason as `ts_ls` (nvim) and `tsserver` (lvim).
  typescript-language-server
)

status=0

# Idempotent as-is: `pnpm add -g` on an installed package is an
# upgrade-or-no-op, so this doubles as the update path.
pnpm add -g "${pkgs[@]}" || status=1

# The directories ~/.prettierrc and ~/eslint.config.mjs import their plugins
# from (see .config/prettier/plugin-php.mjs and .config/eslint/eslint.config.mjs).
# Installed in the repo path rather than through the ~/.config links, so it
# works before the links exist. `update` rather than `install` for the same
# update-path reason as above: the lockfiles are git-ignored, so each moves to
# the newest release in its package.json ranges. A new minor of the 0.x PHP
# plugin needs its range bumped by hand, and so does a TypeScript release past
# what typescript-eslint supports (its peer range stops below 6.1).
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for dir in prettier eslint; do
  pnpm update --dir "$repo_root/.config/$dir" || status=1
done

exit "$status"
