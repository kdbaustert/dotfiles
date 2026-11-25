#!/usr/bin/env bash
#
# Checks that .prettierrc loads its plugins and formats with them. Every
# plugin entry must be a path starting with ".", which Prettier resolves next
# to the config file; a bare package name is looked up from the current
# directory only and breaks every file outside a project that installs it.
# Then the prettier on PATH formats a JS and a PHP sample from a scratch
# directory outside the repo, the way an editor runs it in another project.
# Run it after changing .prettierrc, .config/prettier or setup/pnpm.sh:
#
#   setup/check-prettier.sh
#
# SC2016 is off because the PHP samples' $a and $x are PHP, not shell.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$root/.prettierrc"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/check-prettier.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0

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

while IFS= read -r plugin; do
  case "$plugin" in
    .*) expect "plugin $plugin exists next to .prettierrc" yes \
          "$([ -f "$root/$plugin" ] && echo yes || echo no)" ;;
    *)
      printf 'FAIL: plugin %s is a bare name, found only inside a project that installs it\n' "$plugin" >&2
      failures=$((failures + 1))
      ;;
  esac
done < <(jq -r '.plugins[]?, .overrides[]?.options.plugins[]?' "$config")

if ! command -v prettier >/dev/null 2>&1; then
  printf 'FAIL: prettier is not on PATH; run setup/pnpm.sh\n' >&2
  exit 1
fi
if [ ! -d "$root/.config/prettier/node_modules/@prettier/plugin-php" ]; then
  printf 'FAIL: .config/prettier has no node_modules; run setup/pnpm.sh\n' >&2
  exit 1
fi

# From the scratch directory so nothing in the repo is on the lookup path.
cd "$tmp_dir" || exit 1
printf 'const a = {b:"x", c:[1,2]};\n' >sample.js
printf '<?php\n$a = array(1,2); function foo($x){ return $x+1; }\n' >sample.php

expect 'JS gets single quotes and no semicolons' \
  "const a = { b: 'x', c: [1, 2] }" \
  "$(prettier --config "$config" sample.js 2>&1)"

expect 'PHP formats through the plugin, 4 spaces and short arrays' \
  "$(printf '<?php\n$a = [1, 2];\nfunction foo($x)\n{\n    return $x + 1;\n}')" \
  "$(prettier --config "$config" sample.php 2>&1)"

# The real path: Prettier finds ~/.prettierrc on its own and reaches the
# plugin through the ~/.config/prettier link. Needs a directory under $HOME,
# and only means something on a machine where the link points here.
if [ "$(readlink "$HOME/.prettierrc")" = "$config" ]; then
  home_dir="$(mktemp -d "$HOME/.check-prettier.XXXXXX")"
  trap 'rm -rf "$tmp_dir" "$home_dir"' EXIT
  cp sample.php "$home_dir/"
  expect 'PHP formats through ~/.prettierrc with no --config' \
    "$(prettier --config "$config" sample.php 2>&1)" \
    "$(cd "$home_dir" && prettier sample.php 2>&1)"
else
  echo "skip: ~/.prettierrc is not linked to $config"
fi

if [ "$failures" -gt 0 ]; then
  printf '%d check(s) failed\n' "$failures" >&2
  exit 1
fi
echo 'all prettier checks passed'
