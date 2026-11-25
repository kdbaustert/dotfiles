#!/usr/bin/env bash
#
# Global Composer packages, from Composerfile. bash, not sh: the list is a bash
# array, and on a system where /bin/sh is dash (not macOS's bash-in-POSIX-mode)
# the array assignment is a syntax error.
set -uo pipefail

if ! command -v composer >/dev/null 2>&1; then
  echo "composer not found — skipping (install it via the Brewfile first)." >&2
  exit 0
fi

# The list lives in Composerfile, beside the Brewfile's role for Homebrew. A
# while-read loop instead of mapfile, which macOS's bash 3.2 doesn't have.
composer=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [ -n "$line" ] && composer+=("$line")
done < "$(dirname "$0")/Composerfile"

# bash 3.2 treats an empty array as unset under `set -u`.
if [ "${#composer[@]}" -eq 0 ]; then
  echo "Composerfile lists no packages, skipping." >&2
  exit 0
fi

# Idempotent: `composer global require` on an already-present package resolves
# to the same constraint and no-ops, so this doubles as the update path.
composer global require "${composer[@]}" || exit

# phpcs only finds a standard whose folder is in its installed_paths. phpcs
# keeps the setting in CodeSniffer.conf inside its own vendor folder, so a
# phpcs upgrade wipes it and this script has to run again. Each set replaces
# the whole comma-separated value, so every standard goes into this one call:
# Neutron, plus WPCS and the PHPCSUtils and PHPCSExtra standards WPCS 3 needs
# to load. Setting Neutron alone dropped WPCS on every run.
#
# wpcs brings dealerdirect/phpcodesniffer-composer-installer back in, and its
# plugin registers the same folders during the require above. The set stays
# anyway: the plugin only runs while allow-plugins trusts it, and taking wpcs
# out of the Composerfile would take the plugin, and Neutron's registration,
# with it. setup/check-composer-neutron.sh covers it.
composer_home="$(composer global config home 2>/dev/null)"
standards=(
  automattic/phpcs-neutron-standard
  phpcsstandards/phpcsextra
  phpcsstandards/phpcsutils
  wp-coding-standards/wpcs
)
installed_paths=""

for standard in "${standards[@]}"; do
  if [ -d "$composer_home/vendor/$standard" ]; then
    installed_paths="${installed_paths:+$installed_paths,}$composer_home/vendor/$standard"
  fi
done

if [ -n "$installed_paths" ]; then
  "$composer_home/vendor/bin/phpcs" --config-set installed_paths "$installed_paths"
fi
