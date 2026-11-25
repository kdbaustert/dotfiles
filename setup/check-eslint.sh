#!/usr/bin/env bash
#
# Checks that .config/eslint/eslint.config.mjs, the fallback config linked to
# ~/eslint.config.mjs, loads its plugins and lints JS, TypeScript and Vue with
# them from outside the repo, the way an editor runs eslint in a project with
# no config of its own. Also checks that eslint-config-prettier still comes
# last, that build output is ignored, and that a project's own config wins.
# Run it after changing .config/eslint or setup/pnpm.sh:
#
#   setup/check-eslint.sh
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$root/.config/eslint/eslint.config.mjs"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/check-eslint.XXXXXX")"
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

# Prints the rule IDs eslint reports, sorted and space-separated, with "fatal"
# for a parse error. When eslint can't run at all (a missing plugin, say) the
# JSON is empty and its stderr is printed instead, so the FAIL shows why.
#
# @param $@ arguments for eslint, ending with one file
rules_for() {
  local json

  json="$(eslint --format json "$@" 2>"$tmp_dir/stderr")"
  if [ -z "$json" ]; then
    cat "$tmp_dir/stderr"
    return
  fi

  jq -r '.[0].messages | map(.ruleId // "fatal") | unique | join(" ")' <<<"$json"
}

# Prints the root Neovim's ESLint server started on for a file, or "none".
# Waits for ts_ls first, so plugins and Mason have loaded, then up to 5
# seconds for the ESLint server, which attaches later (measured: after ts_ls
# and vtsls). "none" therefore costs the full 5 seconds. The marker is there
# because the server's own messages land on stdout too.
#
# @param $1 file to open
nvim_eslint_root() {
  nvim --headless "$1" \
    '+lua vim.wait(10000, function() return #vim.lsp.get_clients { bufnr = 0, name = "ts_ls" } > 0 end)' \
    '+lua vim.wait(5000, function() return #vim.lsp.get_clients { bufnr = 0, name = "eslint" } > 0 end)' \
    '+lua local c = vim.lsp.get_clients({ bufnr = 0, name = "eslint" })[1]; io.stdout:write("\neslint-root=", c and c.root_dir or "none", "\n")' \
    +qa 2>/dev/null | sed -n 's/^eslint-root=//p'
}

if ! command -v eslint >/dev/null 2>&1; then
  printf 'FAIL: eslint is not on PATH; run setup/pnpm.sh\n' >&2
  exit 1
fi
if [ ! -d "$root/.config/eslint/node_modules/typescript-eslint" ]; then
  printf 'FAIL: .config/eslint has no node_modules; run setup/pnpm.sh\n' >&2
  exit 1
fi

# From the scratch directory so nothing in the repo is on the lookup path.
cd "$tmp_dir" || exit 1
printf 'const unused = 1\nconsole.log(window, process)\n' >sample.js
printf 'let y: any = 2\nexport default y\n' >sample.ts
# Three attributes on one line is what vue/max-attributes-per-line flags,
# unless eslint-config-prettier has turned it off. The `: number` only parses
# when the TypeScript parser reaches the script block.
printf '<template><div a="1" b="2" c="3">{{ n }}</div></template>\n<script setup lang="ts">\nconst n: number = 1\n</script>\n' >sample.vue
mkdir dist
printf 'foo(\n' >dist/bundle.js

expect 'JS gets the recommended rules and both browser and Node globals' \
  '@typescript-eslint/no-unused-vars' \
  "$(rules_for --config "$config" sample.js)"

expect 'TypeScript parses and gets typescript-eslint rules' \
  '@typescript-eslint/no-explicit-any prefer-const' \
  "$(rules_for --config "$config" sample.ts)"

expect 'Vue parses a TS script block, and prettier turns off layout rules' \
  'vue/multi-word-component-names' \
  "$(rules_for --config "$config" sample.vue)"

expect 'dist/ is ignored' \
  "$(pwd -P)/sample.js $(pwd -P)/sample.ts $(pwd -P)/sample.vue" \
  "$(eslint --config "$config" --format json . 2>/dev/null | jq -r '[.[].filePath] | sort | join(" ")')"

# The real path: eslint finds ~/eslint.config.mjs on its own, walking up from
# the file, and its imports still reach .config/eslint/node_modules through
# the link. Needs a directory under $HOME, and only means something on a
# machine where the link points here.
if [ "$(readlink "$HOME/eslint.config.mjs")" = "$config" ]; then
  home_dir="$(mktemp -d "$HOME/.check-eslint.XXXXXX")"
  trap 'rm -rf "$tmp_dir" "$home_dir"' EXIT
  cp -R sample.js sample.vue dist "$home_dir/"
  mkdir -p "$home_dir/project/.git"
  printf 'console.log(1)\n' >"$home_dir/project/sample.js"
  printf "export default [{ rules: { 'no-console': 'error' } }]\n" \
    >"$home_dir/project/eslint.config.mjs"

  expect 'Vue lints through ~/eslint.config.mjs with no --config' \
    'vue/multi-word-component-names' \
    "$(cd "$home_dir" && rules_for sample.vue)"

  # The ignores resolve against $HOME here, not the current directory as they
  # do with --config, so the dist/ check above doesn't cover this path.
  expect 'dist/ is ignored through ~/eslint.config.mjs' \
    'project/eslint.config.mjs project/sample.js sample.js sample.vue' \
    "$(cd "$home_dir" && eslint --format json . 2>/dev/null \
      | jq -r --arg dir "$(pwd -P)/" '[.[].filePath | ltrimstr($dir)] | sort | join(" ")')"

  expect "a project's own config wins over ~/eslint.config.mjs" \
    'no-console' \
    "$(cd "$home_dir/project" && rules_for sample.js)"

  # The guard in .config/nvim/lua/plugins/lsp.lua. Without it the server
  # starts on $HOME for a loose file and only prints "Unable to find ESLint
  # library". The project case proves the guard still lets real roots through.
  # Needs the server Mason installs; ts_ls is in the Mason list.
  if command -v nvim >/dev/null 2>&1 \
    && [ -x "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin/vscode-eslint-language-server" ]; then
    expect "Neovim's ESLint server stays off a loose file opened from \$HOME" \
      none \
      "$(cd "$HOME" && nvim_eslint_root "$home_dir/sample.js")"

    expect "Neovim's ESLint server starts on a project root" \
      "$home_dir/project" \
      "$(cd "$home_dir/project" && nvim_eslint_root sample.js)"
  else
    echo "skip: Neovim or Mason's ESLint server is not installed"
  fi
else
  echo "skip: ~/eslint.config.mjs is not linked to $config"
fi

if [ "$failures" -gt 0 ]; then
  printf '%d check(s) failed\n' "$failures" >&2
  exit 1
fi
echo 'all eslint checks passed'
