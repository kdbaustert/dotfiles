#==============================================================================
#  zinit — plugin manager bootstrap + plugins
#------------------------------------------------------------------------------
#  Philosophy: zinit manages zsh *plugins* only (completions, autosuggestions,
#  syntax highlighting, fzf-tab, version managers). CLI *binaries* (eza, bat,
#  fd, fzf, zoxide, atuin, navi, delta, starship, …) come from Homebrew and are
#  wired up in .zshrc.
#
#  This avoids the arm64/x86_64 gh-r mismatches that previously broke mcfly,
#  and means EVERY plugin here can be turbo-deferred — nothing zinit loads is
#  needed before the first prompt, so none of it is on the critical path.
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

# Keep the completion dump in the zsh cache dir alongside the other generated
# artefacts, instead of dropping a 64K ~/.zcompdump in $HOME. Read by zicompinit
# in the turbo block below, so it must be set before that runs.
ZINIT[ZCOMPDUMP_PATH]="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/zcompdump"

setopt PROMPT_SUBST

# --- Prompt: starship ---------------------------------------------------------
# Starship now comes from Homebrew (declared in homebrew/Brewfile) and is
# initialised from .zshrc via the cached `starship init zsh` output.
#
# It used to be fetched here as a gh-r binary, which made it the ONE plugin
# loaded eagerly — a prompt cannot be turbo-deferred, since it has to exist
# before the first prompt is drawn. That put zinit's full plugin-load machinery
# (~16ms, the single largest entry in `zprof`) on the critical path just to put
# one binary on $PATH and eval its init. Homebrew already provides every other
# CLI binary this config uses (eza, bat, fd, fzf, zoxide, atuin, navi, delta,
# vivid), so this is now consistent with the rest — and `brew upgrade` handles
# updates instead of `zinit update`.

# --- Version managers (turbo) -------------------------------------------------
# Node — zsh-nvm with lazy loading (NVM_LAZY_LOAD=true, set in .zprofile): the
# heavy nvm.sh is never sourced at startup. The plugin instead defines function
# shims for node/npm/npx/nvm that source it on first call.
#
# nvm is the ONLY node version manager here. asdf used to be declared in the
# Brewfile alongside it, but it had zero plugins installed and was never
# initialised in any shell file, so it managed nothing — it has been removed
# rather than wired up.
#
# The previous version of this comment claimed nvm managed no versions and that
# `node` therefore resolved to Homebrew's. Both halves are now wrong:
# ~/.nvm/versions/node holds v26.5.0 and ~/.nvm/alias/default is `lts`, so in an
# interactive shell `node` is the shim *function* and gives v26.5.0 — a function
# outranks any $path lookup, so Homebrew's v26.7.0 does not win despite
# /opt/homebrew/bin being first in the path array. Homebrew's node is what
# non-interactive shells and scripts get, since they never load this plugin.
# Verify with `whence -w node` in a real interactive shell — NOT `zsh -i -c`,
# which exits before the first prompt and so before turbo fires.
zinit ice wait lucid
zinit light lukechilds/zsh-nvm

# Python — pyenv was removed. It managed zero versions (~/.pyenv/versions empty,
# `pyenv global` was `system`), so its shims and turbo-deferred `pyenv init`
# resolved python3 to the same Homebrew python they'd have hit anyway. If
# per-project Python versions are ever needed, add pyenv back here — or reach
# for mise and let one tool cover Node and Python together.

# --- Completion initialisation ------------------------------------------------
# Replaces the bare `ZINIT[COMPINIT_OPTS]=-C; zicompinit` that used to sit in
# fzf-tab's atinit. Two things were wrong with that:
#
#   1. `compinit -C` trusts the existing dump and never rebuilds it, so a dump
#      written once was reused forever. This machine's ~/.zcompdump was months
#      stale, meaning completions for anything installed since simply never
#      appeared — `rehash true` finds new *commands*, but not new completion
#      *functions*.
#   2. When no dump existed at all, the turbo-run zicompinit did not write one
#      (verified: a manual zicompinit in the same shell does). So a fresh machine
#      would silently pay a full, uncached compinit on every single start.
#
# This does a full, checked compinit once every 24h — and whenever the dump is
# missing — and takes the cheap cached path the rest of the time.
zsh_compinit() {
  # localoptions: (#q…) glob qualifiers need EXTENDED_GLOB. .zshrc happens to
  # set it, but this function must not silently depend on that — without it the
  # test below fails open and every start takes the cached path forever.
  setopt localoptions extendedglob
  autoload -Uz compinit compdump
  local dump="${ZINIT[ZCOMPDUMP_PATH]}"

  # (#qN.mh-24) — glob qualifier: exists (N: no error if not), plain file (.),
  # mtime less than 24h ago (mh-24). A match means "fresh". The qualifier must
  # be globbed in an array assignment; inside [[ ]] no filename generation
  # happens at all and the test would always fall through to the cached branch.
  local -a fresh
  fresh=( ${dump}(#qN.mh-24) )

  if (( ${#fresh} )); then
    compinit -C -d "$dump"  # fresh: trust it, skip the security/newness scan
  else
    compinit -d "$dump"     # missing or >24h old: full scan, rewrites the dump
  fi

  # Belt and braces for case 2 above: guarantee a dump exists on disk, so the
  # next start can take the cached path even if compinit declined to write one.
  [[ -f $dump ]] || compdump
}

# --- Completions, fzf-tab, autosuggestions, syntax highlighting ---------------
# One ordered turbo block:
#   1. zsh-completions     — extra completion definitions (blockf: don't pollute fpath)
#   2. fzf-tab             — fzf-driven completion menu; its atinit runs compinit
#                            ONCE (zsh_compinit) so completions exist before it hooks
#   3. zsh-autosuggestions — fish-style suggestions (started via atload)
#   4. fast-syntax-highlighting — MUST be loaded last
zinit wait lucid blockf for \
  zsh-users/zsh-completions

zinit wait lucid for \
  has'fzf' atinit"zsh_compinit; zicdreplay" \
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
#   - OMZP::safe-paste    — bracketed-paste-magic; see the block below it, which
#                           is not optional.
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

# safe-paste: on zsh >= 5.1 (this is 5.9.2) the plugin collapses to three lines —
# it re-sets the zle_bracketed_paste option and swaps zsh's *built-in*
# bracketed-paste widget for bracketed-paste-magic. Worth being precise about
# what that buys, because it is not the obvious thing: the built-in widget
# already stops a pasted newline from auto-executing. What the magic widget adds
# is running pasted text through ZLE widgets, so url-quote-magic (URL escaping)
# applies to a paste instead of being bypassed.
#
# That processing is per-character, and per-character is exactly the case
# zsh-autosuggestions documents as "slow pasting" — every pasted char would
# otherwise re-enter the autosuggest self-insert wrapper, and with
# fast-syntax-highlighting also hooked in, a large paste crawls. The two zstyles
# below are upstream's own fix: swap self-insert to a bare url-quote-magic for
# the duration of the paste, then restore whatever widget was there. Without
# them this plugin is a net LOSS on this config — do not add one without the
# other, and do not reorder them after the plugin list.
autoload -Uz url-quote-magic
_zsh_paste_init() {
  # widgets[self-insert] reads like "user:autosuggest-widget-self-insert";
  # [2,3] strips the "user:" tag and keeps the function name.
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}
_zsh_paste_finish() { zle -N self-insert $OLD_SELF_INSERT }
zstyle :bracketed-paste-magic paste-init   _zsh_paste_init
zstyle :bracketed-paste-magic paste-finish _zsh_paste_finish

zinit wait lucid for \
  OMZP::sudo \
  OMZP::safe-paste \
  hlissner/zsh-autopair \
  MichaelAquilina/zsh-you-should-use \
  wfxr/forgit \
  MichaelAquilina/zsh-auto-notify \
  olets/zsh-abbr

# --- fzf-git.sh (turbo) -------------------------------------------------------
# fzf widgets that INSERT a git object into the line you are already typing:
# files, branches, tags, remotes, hashes, stashes, reflogs, each_ref, worktrees.
# Complements forgit above rather than overlapping it — forgit gives whole
# interactive *commands* (fga/fgd/glo), this gives *completions* mid-command,
# e.g. `git rebase -i <^X^G h>`. Previews use bat and delta, both already here.
#
# REBOUND OFF ^G, deliberately. Upstream's __fzf_git_init hardcodes
#   bindkey -M $m '^g^<x>'   and   bindkey -M $m '^g<x>'
# for every object, in the emacs, viins and vicmd keymaps, with no prefix option
# to override. That collides with navi's single-key ^G widget (bound in .zshrc
# from the cached `navi widget zsh`) — though not by deleting it, which is worth
# stating precisely because the failure is intermittent rather than total:
#
#   Binding any '^g<x>' sequence promotes ^G to a PREFIX key. zsh keeps the
#   standalone ^G binding as a fallback, so `bindkey '^g'` still reports
#   _navi_widget — but it can only resolve it after KEYTIMEOUT (40 = 0.4s here)
#   proves no continuation is coming. So navi still works, with a 0.4s stall,
#   and typing ^G followed quickly by any of f/b/t/r/h/s/l/e/w/? runs fzf-git
#   instead of navi. A lag that only sometimes ends in the wrong widget is worse
#   to live with than a clean break, hence moving fzf-git rather than tolerating it.
#
# navi keeps ^G — it was here first and is in the muscle memory — so fzf-git
# moves to ^X^G, matching the ^X^E (edit-command-line) and ^X^X (pay-respects)
# prefix convention already in use. ^X^G is genuinely free: the emacs keymap
# binds ^Xg and ^XG to list-expand, but those are ^X-then-g, a different
# sequence from ^X-then-^G.
#
#   ^X^G then f b t r h s l e w   (or ^F ^B ^T … — both forms bound, as upstream)
#   ^X^G ?                        lists the bindings
#
# Change the prefix in one place here. The atload runs immediately after the
# plugin sources, i.e. after its own bindkey calls, so it can undo them.
FZF_GIT_PREFIX='^X^G'
_fzf_git_rebind() {
  local o k m
  # Same object list upstream passes to __fzf_git_init; '?list_bindings' is the
  # odd one out — its widget really is named fzf-git-?list_bindings-widget and
  # its key is '?', per the ${o[1]} == "?" branch in the plugin.
  for o in files branches tags remotes hashes stashes lreflogs each_ref \
           worktrees '?list_bindings'; do
    k=${o[1]}
    for m in emacs viins vicmd; do
      bindkey -M $m -r "^g^$k" "^g$k" 2>/dev/null
    done
    bindkey -M emacs "${FZF_GIT_PREFIX}^$k" "fzf-git-$o-widget"
    bindkey -M emacs "${FZF_GIT_PREFIX}$k"  "fzf-git-$o-widget"
  done
  # Removing the ^g<x> sequences above does NOT restore the plain ^G binding the
  # plugin overwrote when it made ^G a prefix — that has to be put back by hand.
  (( ${+widgets[_navi_widget]} )) && bindkey -M emacs '^g' _navi_widget
}
zinit ice wait lucid has'fzf' pick'fzf-git.sh' atload'_fzf_git_rebind'
zinit light junegunn/fzf-git.sh

# --- zsh-bench (turbo, program not plugin) ------------------------------------
# Measures *perceived* interactive latency — first-prompt-lag, first-command-lag,
# input-lag, exit-time — by driving a real interactive zsh under a pty. This is
# the thing the turbo-defer architecture at the top of this file is actually
# optimising for, and the thing zprof cannot see: zprof times shell *functions*,
# so it attributes nothing to the gap between a keypress and the response.
#
# as"program" is load-bearing: it puts the repo directory on $PATH and does NOT
# source anything, which is correct — this is a benchmark harness, not a plugin.
# Nothing here runs at shell startup.
#
#   zsh-bench                 # summary for the current interactive config
#   zsh-bench --iters 20      # tighter confidence interval
zinit ice wait lucid as"program" pick"zsh-bench"
zinit light romkatv/zsh-bench
