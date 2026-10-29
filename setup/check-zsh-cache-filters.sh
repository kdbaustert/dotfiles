#!/usr/bin/env bash
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
actual="$(printf '%s\n' \
  "eval \$__fzf_key_bindings_options" \
  "eval \$__fzf_completion_options" \
  | zsh -c 'source "$1"; zcache_post_fzf' _ "$root/zsh/extra/cache.zsh")"
expected="$(printf '%s\n' \
  '# zcache-filter:fzf:v1' \
  "eval \"\${\${__fzf_key_bindings_options// zle on/}// zle off/}\"" \
  "eval \"\${\${__fzf_completion_options// zle on/}// zle off/}\"")"

if [ "$actual" != "$expected" ]; then
  printf 'FAIL: fzf cache filter output differs\nExpected:\n%s\nActual:\n%s\n' \
    "$expected" "$actual" >&2
  exit 1
fi

printf '%s\n' 'ok: fzf cache filter omits zle from option restores'

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/zsh-cache-filter.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir "$tmp_dir/init"
printf '%s\n' '# stale filter output' >"$tmp_dir/init/fzf.zsh"

regenerated="$(zsh -ifc \
  'source "$1"; ZSH_CACHE_INIT_DIR="$2"; zcache fzf fzf --zsh; IFS= read -r marker < "$ZSH_CACHE_INIT_DIR/fzf.zsh"; print -r -- "$marker"' \
  _ "$root/zsh/extra/cache.zsh" "$tmp_dir/init" 2>&1)"
if [ "$regenerated" != '# zcache-filter:fzf:v1' ]; then
  printf 'FAIL: stale fzf cache was not regenerated\n%s\n' "$regenerated" >&2
  exit 1
fi

printf '%s\n' 'ok: stale fzf cache regenerates when its filter version changes'

fallback_errors="$(zsh -ifc \
  'source "$1"; ZSH_CACHE_INIT_DIR=/dev/null; zcache fzf fzf --zsh' \
  _ "$root/zsh/extra/cache.zsh" 2>&1 >/dev/null)"
if [[ "$fallback_errors" == *"can't change option: zle"* ]]; then
  printf 'FAIL: fzf fallback tried to restore zle\n%s\n' "$fallback_errors" >&2
  exit 1
fi

printf '%s\n' 'ok: fzf cache fallback applies the filter'
