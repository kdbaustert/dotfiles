#!/usr/bin/env bash
#
# Global Composer packages. bash, not sh: the list below is a bash array, and
# on a system where /bin/sh is dash (not macOS's bash-in-POSIX-mode) the array
# assignment is a syntax error.
set -uo pipefail

if ! command -v composer >/dev/null 2>&1; then
  echo "composer not found — skipping (install it via the Brewfile first)." >&2
  exit 0
fi

composer=(
  laravel/installer
  laravel/valet
  phpunit/phpunit
  friendsofphp/php-cs-fixer
  squizlabs/php_codesniffer
  automattic/phpcs-neutron-standard
  automattic/phpcs-neutron-ruleset
  dealerdirect/phpcodesniffer-composer-installer
  phpmd/phpmd
  phpstan/phpstan
  szepeviktor/phpstan-wordpress
  php-stubs/woocommerce-stubs
  wp-coding-standards/wpcs
  wptrt/wpthemereview
  woocommerce/woocommerce-sniffs
)

# This line was missing: the script declared the array above and then ended, so
# it had always been a no-op — every run "succeeded" without installing a thing.
composer global require "${composer[@]}"
