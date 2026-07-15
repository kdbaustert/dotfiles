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
# heavy nvm.sh is only sourced on first `node`/`npm`/`nvm` use. Kept on purpose,
# even though nvm currently manages no versions (~/.nvm/versions/node is empty
# and nothing in ~/Development or ~/Sites has a .nvmrc): it's here for
# per-project Node versions when they're needed, and lazy loading means an
# unused nvm costs ~nothing. Until `nvm install` is run, `node` resolves to
# Homebrew's (declared in the Brewfile).
zinit ice wait lucid
zinit light lukechilds/zsh-nvm

# Python — pyenv was removed. It managed zero versions (~/.pyenv/versions empty,
# `pyenv global` was `system`), so its shims and turbo-deferred `pyenv init`
# resolved python3 to the same Homebrew python they'd have hit anyway. If
# per-project Python versions are ever needed, add pyenv back here — or reach
# for mise and let one tool cover Node and Python together.

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

# --- carapace: completions for tools that ship none we can use ----------------
# Replaces the hand-rolled `_gh` fpath cache and the pnpm precmd-retry hook that
# used to live above. Registered per-command ON PURPOSE:
#
#   source <(carapace _carapace zsh)   # DON'T — one compdef hijacks 653 commands
#   source <(carapace gh zsh)          # scoped: emits `compdef _gh_completion gh`
#
# The wholesale form would take over `git`, `ssh`, `man`, `tar`, `find`… clobbering
# zsh's native _git and, with it, the `:completion:*:git-checkout:*` /
# `:fzf-tab:complete:git-(add|diff|…)` zstyles in .zshrc — those match on _git's
# sub-context, which _carapace_completer never produces. Add a line per tool that
# genuinely lacks a good native completion; leave the rest to zsh.
# Deferred via turbo so the two subprocesses land after the first prompt, and
# ordered after the block above so compdef exists by the time they run.
zinit ice wait lucid id-as'carapace-init' has'carapace' \
  atload'source <(carapace gh zsh); source <(carapace pnpm zsh)'
zinit light zdharma-continuum/null

# --- Extra behavior plugins (turbo) -------------------------------------------
#   - zsh-autopair        — auto-insert/delete matching brackets, quotes, parens
#   - zsh-you-should-use  — nags when a full command has an existing alias
#   - forgit              — fzf-powered git (glo, gss, gcb…); honours delta
#   - zsh-auto-notify     — desktop notification when a long command finishes
#                           (uses terminal-notifier, installed via Homebrew)
#   - OMZP::sudo          — ESC ESC prepends `sudo` to the current line (or the
#                           last command, on an empty line). Self-contained: it
#                           pulls no OMZ lib. ^X^X is pay-respects' inline fixer
#                           and ^X^E is edit-command-line — no collision.
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

# abbr: fish-style abbreviations that expand inline as you type. Unlike an
# alias, the *expanded* command is what runs and what lands in history — pairs
# well with you-should-use. Manage with `abbr add ga='git add'`, `abbr list`,
# `abbr erase`. Definitions are seeded in $DOTFILES/zsh/abbreviations (pointed
# at below); abbr reads/writes that file directly so runtime `abbr add`s stay
# version-controlled. Must be set before the plugin loads.
export ABBR_USER_ABBREVIATIONS_FILE="$DOTFILES/zsh/abbreviations"
zinit wait lucid for \
  OMZP::sudo \
  hlissner/zsh-autopair \
  MichaelAquilina/zsh-you-should-use \
  wfxr/forgit \
  MichaelAquilina/zsh-auto-notify \
  olets/zsh-abbr
