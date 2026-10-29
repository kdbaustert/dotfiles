#==============================================================================
#  cache.zsh: cache the output of `<tool> init zsh`-style generators
#------------------------------------------------------------------------------
#  Tools like starship, zoxide, atuin, navi and fzf don't ship a static zsh
#  integration file; they print one on stdout and expect you to eval it:
#
#      eval "$(zoxide init zsh)"
#
#  That spawns a process on every single shell start. Individually each is only
#  1-5ms, but this config runs seven of them, and they are strictly serial: the
#  shell blocks on each fork+exec before it can draw a prompt.
#
#  The output of these generators is static: it defines functions, widgets and
#  hooks, and reads no per-session state. (Config is read later, at prompt time,
#  e.g. starship re-reads starship.toml on every prompt, so caching the init
#  does not freeze your prompt config.) So it can be generated once, written to
#  disk, and sourced thereafter.
#
#  Invalidation is by binary mtime: if the tool is newer than its cache, the
#  cache is regenerated. `brew upgrade` rewrites the binary, so upgrades are
#  picked up automatically with no manual step.
#==============================================================================

typeset -g ZSH_CACHE_INIT_DIR="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/init"

# fzf's generated integrations snapshot every option, then restore them through
# the `options` parameter. zle cannot be assigned through that parameter, so
# omit it from both restore expressions; fzf does not change the option itself.
zcache_post_fzf() {
  print '# zcache-filter:fzf:v1'
  sed \
    -e 's|eval $__fzf_key_bindings_options|eval "${${__fzf_key_bindings_options// zle on/}// zle off/}"|' \
    -e 's|eval $__fzf_completion_options|eval "${${__fzf_completion_options// zle on/}// zle off/}"|'
}

# zcache <name> <command> [args...]
#
# Sources the cached stdout of `<command> [args...]`, regenerating it when the
# command's binary is newer than the cache (or the cache is missing/empty).
# A no-op, and a successful one, if the command isn't installed, so callers
# don't need their own `command -v` guard.
#
# If a function named `zcache_post_<name>` exists, the generated output is piped
# through it before being written. Its first line is a filter-version marker;
# bump the callback's marker and the matching check below when its behavior
# changes, so an old cache is regenerated even when the tool binary is unchanged.
# See zcache_post_starship in .zshrc. The filter runs once per regeneration,
# not per shell start, so it can be as expensive as it likes.
zcache() {
  local name=$1; shift
  # $commands is zsh's builtin name→path hash; a subscript miss is the "not
  # installed" case, so an empty result returns 0, the same as a
  # `command -v X && eval ...` guard would.
  #
  # Not `bin=$(command -v "$1")`: a command substitution forks a subshell, and
  # with seven zcache/zcache_value calls on the startup path that costs ~3.5ms of
  # pure fork overhead, more than everything else this file saves. The hash
  # does the same PATH search in-process. Every caller here resolves an external
  # binary, which is exactly what $commands covers (not functions or aliases).
  local bin=${commands[$1]}
  [[ -n $bin ]] || return 0

  local cache="$ZSH_CACHE_INIT_DIR/$name.zsh" regenerate=false filter_marker

  if [[ ! -s $cache || $bin -nt $cache ]]; then
    regenerate=true
  elif (( ${+functions[zcache_post_$name]} )); then
    IFS= read -r filter_marker < "$cache"
    [[ $filter_marker == "# zcache-filter:$name:v1" ]] || regenerate=true
  fi

  # -s: non-empty. A zero-byte cache means a previous generation failed (tool
  # errored, disk full); treat it as absent rather than sourcing nothing and
  # silently losing the integration forever.
  if [[ $regenerate == true ]]; then
    [[ -d $ZSH_CACHE_INIT_DIR ]] || command mkdir -p "$ZSH_CACHE_INIT_DIR"
    # Generate to a temp file and move into place, so a crash mid-write can't
    # leave a truncated cache that sources as a syntax error on next start.
    local tmp="$cache.$$.tmp"
    if "$@" >| "$tmp" 2>/dev/null && [[ -s $tmp ]]; then
      # Optional per-generator filter (see the header). Only replace the file if
      # the filter succeeds and produces something; a broken filter must not be
      # able to turn a working integration into an empty cache.
      if (( ${+functions[zcache_post_$name]} )); then
        if "zcache_post_$name" < "$tmp" >| "$tmp.f" 2>/dev/null && [[ -s $tmp.f ]]; then
          command mv -f "$tmp.f" "$tmp"
        else
          command rm -f "$tmp.f"
        fi
      fi
      command mv -f "$tmp" "$cache"
      # Byte-compile: `source` prefers a .zwc that is newer than its source.
      zcompile -R -- "$cache" 2>/dev/null
    else
      command rm -f "$tmp"
      # Generation failed: apply the same filter before eval so integrations
      # remain correct this session, then retry the cache next start.
      local generated
      generated="$("$@" 2>/dev/null)"
      if (( ${+functions[zcache_post_$name]} )); then
        generated="$(print -r -- "$generated" | "zcache_post_$name")"
      fi
      eval "$generated"
      return 0
    fi
  fi

  source "$cache"
}

# zcache_value <name> <var> <command> [args...]
#
# As zcache, but for generators that print a value rather than zsh code
# (vivid, which prints an LS_COLORS string). Caches `export <var>=<value>`.
zcache_value() {
  local name=$1 var=$2; shift 2
  local bin=${commands[$1]}   # see zcache above: hash lookup, not a forking $( )
  [[ -n $bin ]] || return 0

  local cache="$ZSH_CACHE_INIT_DIR/$name.zsh"

  if [[ ! -s $cache || $bin -nt $cache ]]; then
    [[ -d $ZSH_CACHE_INIT_DIR ]] || command mkdir -p "$ZSH_CACHE_INIT_DIR"
    local val tmp="$cache.$$.tmp"
    val=$("$@" 2>/dev/null)
    if [[ -n $val ]]; then
      # ${(q+)} picks the cheapest correct quoting for the value.
      print -r -- "export $var=${(q+)val}" >| "$tmp" \
        && command mv -f "$tmp" "$cache" \
        && zcompile -R -- "$cache" 2>/dev/null
    else
      command rm -f "$tmp"
      return 0
    fi
  fi

  source "$cache"
}

# zcache_clear: drop every cached init file. Use after changing a generator's
# arguments (e.g. a different vivid theme), which mtime-based invalidation can't
# see. Caches rebuild on the next shell start.
zcache_clear() {
  command rm -rf -- "$ZSH_CACHE_INIT_DIR"
  print "zcache: cleared $ZSH_CACHE_INIT_DIR — open a new shell to rebuild."
}
