#==============================================================================
#  zinit — plugin manager bootstrap + plugins
#------------------------------------------------------------------------------
#  Philosophy: zinit manages zsh *plugins* only (completions, autosuggestions,
#  syntax highlighting, fzf-tab, version managers). CLI *binaries* (eza, bat,
#  fd, fzf, zoxide, atuin, navi, delta, …) come from Homebrew and are wired up
#  in .zshrc. Starship is the one binary we fetch via zinit, because it is not
#  installed through Homebrew on this machine.
#
#  This avoids the arm64/x86_64 gh-r mismatches that previously broke mcfly,
#  and keeps the load in a single, ordered turbo block.
#==============================================================================

# --- Bootstrap ----------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -f $ZINIT_HOME/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{160}Installing zinit (zdharma-continuum)…%f"
  command mkdir -p "$(dirname "$ZINIT_HOME")"
  command git clone -q --depth=1 https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" \
    && print -P "%F{34}▓▒░ Installation successful.%f" \
    || print -P "%F{160}▓▒░ Clone failed.%f"
fi

source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

setopt PROMPT_SUBST

# --- Prompt: starship ---------------------------------------------------------
# Fetched as a binary (arm64); init is eval'd on load so it works regardless of
# whether the plugin dir was freshly cloned.
zinit ice from"gh-r" as"command" bpick"*aarch64-apple*.tar.gz" \
  atload'eval "$(starship init zsh)"'
zinit light starship/starship

# --- Version managers (turbo) -------------------------------------------------
# Node — zsh-nvm with lazy loading (NVM_LAZY_LOAD=true, set in .zprofile) so the
# heavy nvm.sh is only sourced on first `node`/`npm`/`nvm` use.
zinit ice wait lucid
zinit light lukechilds/zsh-nvm

# Python — pyenv. Deferred via turbo so it never blocks the prompt (it was the
# single biggest synchronous cost, ~0.12s). `--no-rehash` skips rebuilding shims
# on every shell; rehash still runs automatically on `pyenv install`. The init
# prepends ~/.pyenv/shims to PATH itself, just a hair after the first prompt.
zinit ice wait lucid id-as'pyenv-init' \
  atload'eval "$(pyenv init - --no-rehash zsh)"'
zinit light zdharma-continuum/null

# --- Tool completions not shipped via Homebrew --------------------------------
# gh emits a clean `#compdef` script. Cache it once and prepend to fpath *before*
# compinit runs (zicompinit, in the turbo block below). Delete the cache file to
# refresh after a `gh` upgrade. (pnpm needs node, which we lazy-load, so it can't
# be generated at startup; Taskwarrior's `task` ships its own completions.)
() {
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
  [[ -d $cache ]] || command mkdir -p "$cache"
  if [[ ! -s $cache/_gh ]] && (( $+commands[gh] )); then
    gh completion -s zsh > "$cache/_gh"
  fi
  fpath=("$cache" $fpath)
}

# pnpm completion — pnpm shells out to `node` (lazy-loaded via nvm) to print its
# completion, and the script it emits calls `compdef`. Neither is ready at
# startup, so a precmd hook retries each prompt until both exist, then generates
# + caches once, sources it, and removes itself. Subsequent shells hit the cache
# on the first prompt after compinit. Delete the cache file to refresh.
() {
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions/pnpm.zsh"
  autoload -Uz add-zsh-hook
  _pnpm_comp_setup() {
    (( $+functions[compdef] )) || return            # wait for compinit (turbo)
    if [[ ! -s $cache ]]; then
      (( $+commands[node] && $+commands[pnpm] )) || return   # wait for nvm/node
      pnpm completion zsh >| "$cache" 2>/dev/null || { command rm -f "$cache"; return; }
    fi
    source "$cache"
    add-zsh-hook -d precmd _pnpm_comp_setup         # one-shot
    unfunction _pnpm_comp_setup
  }
  add-zsh-hook precmd _pnpm_comp_setup
}

# --- Completions, fzf-tab, autosuggestions, syntax highlighting ---------------
# One ordered turbo block:
#   1. zsh-completions     — extra completion definitions (blockf: don't pollute fpath)
#   2. fzf-tab             — fzf-driven completion menu; its atinit runs compinit
#                            ONCE (zicompinit) so completions exist before it hooks
#   3. zsh-autosuggestions — fish-style suggestions (started via atload)
#   4. fast-syntax-highlighting — MUST be loaded last
zinit wait lucid blockf for \
  zsh-users/zsh-completions

zinit wait lucid for \
  has'fzf' atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    Aloxaf/fzf-tab \
  atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  zdharma-continuum/fast-syntax-highlighting

# --- Extra behavior plugins (turbo) -------------------------------------------
#   - zsh-autopair        — auto-insert/delete matching brackets, quotes, parens
#   - zsh-you-should-use  — nags when a full command has an existing alias
#   - forgit              — fzf-powered git (glo, gss, gcb…); honours delta
#   - zsh-auto-notify     — desktop notification when a long command finishes
#                           (uses terminal-notifier, installed via Homebrew)
#
# forgit: rename the 4 helpers that collide with our plain-git aliases in
# aliases.zsh (ga/gd/grh/gco). The f-prefixed names give the interactive
# versions; the originals stay as our git shortcuts. Must be set before load.
forgit_add=fga
forgit_diff=fgd
forgit_reset_head=fgrh
forgit_checkout_commit=fgco

# auto-notify: only ping for commands slower than the threshold, and never for
# interactive/long-lived TUIs we run in the foreground on purpose.
export AUTO_NOTIFY_THRESHOLD=20
export AUTO_NOTIFY_IGNORE=(nvim hx micro vim man less ssh tmux fzf navi \
  yazi ranger nnn xplr lazygit gitui btop htop top watch tail)

zinit wait lucid for \
  hlissner/zsh-autopair \
  MichaelAquilina/zsh-you-should-use \
  wfxr/forgit \
  MichaelAquilina/zsh-auto-notify
