#!/usr/bin/env bash
#
# Runs setup/composer.sh against a stub composer and a stub phpcs and checks
# the phpcs registration that follows the install: phpcs gets every installed
# standard's folder in one installed_paths value, so registering Neutron can't
# drop WPCS, and isn't called when no standard is there or the install failed.
# An empty `composer global config home` fails the script instead of skipping
# the registration without a word.
# Run it after changing composer.sh:
#
#   setup/check-composer-neutron.sh
#
# SC2016 is off because the stub bodies are meant to expand later, in the stub.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/composer-neutron.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0
composer_home="$tmp_dir/home"
neutron="$composer_home/vendor/automattic/phpcs-neutron-standard"
phpcs_log="$tmp_dir/phpcs.log"

# `global require` exits with $STUB_REQUIRE_EXIT; `global config home` prints
# the fake home.
mkdir -p "$tmp_dir/bin" "$composer_home/vendor/bin"
cat >"$tmp_dir/bin/composer" <<'EOF'
#!/bin/bash
case "$2" in
  require) exit "${STUB_REQUIRE_EXIT:-0}" ;;
  config) printf '%s\n' "$STUB_HOME" ;;
esac
EOF

cat >"$composer_home/vendor/bin/phpcs" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$STUB_PHPCS_LOG"
EOF
chmod +x "$tmp_dir/bin/composer" "$composer_home/vendor/bin/phpcs"

# Runs composer.sh with only the stubs on PATH and prints its exit status,
# then what phpcs was called with. STUB_REQUIRE_EXIT in the caller's
# environment reaches the composer stub, and so does STUB_HOME when set, even
# to empty.
run_composer_script() {
  : >"$phpcs_log"
  env -i PATH="$tmp_dir/bin:/usr/bin:/bin" STUB_HOME="${STUB_HOME-$composer_home}" \
    STUB_PHPCS_LOG="$phpcs_log" STUB_REQUIRE_EXIT="${STUB_REQUIRE_EXIT:-0}" \
    "$root/setup/composer.sh" >/dev/null 2>&1
  printf '<%s>' "$?"
  cat "$phpcs_log"
}

# @param $1 description
# @param $2 expected text
# @param $3 actual text
expect() {
  if [ "$2" = "$3" ]; then
    printf 'ok: %s\n' "$1"
  else
    printf 'FAIL: %s\nExpected:\n%s\nActual:\n%s\n' "$1" "$2" "$3" >&2
    failures=$((failures + 1))
  fi
}

expect 'no Neutron package, phpcs is left alone' '<0>' "$(run_composer_script)"

mkdir -p "$neutron"
expect 'Neutron is registered after the install' \
  "<0>--config-set installed_paths $neutron" "$(run_composer_script)"

vendor="$composer_home/vendor"
mkdir -p "$vendor/phpcsstandards/phpcsextra" "$vendor/phpcsstandards/phpcsutils" \
  "$vendor/wp-coding-standards/wpcs"
expect 'WPCS and its dependencies are registered beside Neutron' \
  "<0>--config-set installed_paths $neutron,$vendor/phpcsstandards/phpcsextra,$vendor/phpcsstandards/phpcsutils,$vendor/wp-coding-standards/wpcs" \
  "$(run_composer_script)"

expect 'a failed install keeps its status and skips phpcs' '<2>' \
  "$(STUB_REQUIRE_EXIT=2 run_composer_script)"

expect 'an empty composer home fails and skips phpcs' '<1>' \
  "$(STUB_HOME='' run_composer_script)"

exit "$((failures > 0))"
