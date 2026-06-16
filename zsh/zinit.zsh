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
