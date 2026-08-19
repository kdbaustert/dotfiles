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
#
#  File order is deliberate and is the one thing to preserve when editing:
#    1. Bootstrap          — clone/source zinit itself
#    2. Helper functions   — referenced by ices below, so must exist first
#    3. Plugin config      — every var a plugin reads AT SOURCE TIME
#    4. Plugin loading     — the only section that calls `zinit`
#
#  Sections 3 and 4 used to be interleaved, which made "this must be set before
#  the plugin loads" a property of where a line happened to sit rather than
#  something the file enforces. Keeping all configuration above all loading
#  makes that constraint structural: anything in section 3 is guaranteed to
#  precede every plugin, so a new export cannot be added in the wrong place.
#==============================================================================

#------------------------------------------------------------------------------
# 1. Bootstrap
#------------------------------------------------------------------------------
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
# artefacts, instead of dropping a 64K ~/.zcompdump in $HOME. Read by
# zsh_compinit in section 2, so it must be set before that runs.
ZINIT[ZCOMPDUMP_PATH]="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/zcompdump"

setopt PROMPT_SUBST

# Prompt: starship now comes from Homebrew (declared in homebrew/Brewfile) and
# is initialised from .zshrc via the cached `starship init zsh` output.
#
# It used to be fetched here as a gh-r binary, which made it the ONE plugin
# loaded eagerly — a prompt cannot be turbo-deferred, since it has to exist
# before the first prompt is drawn. That put zinit's full plugin-load machinery
# (~16ms, the single largest entry in `zprof`) on the critical path just to put
# one binary on $PATH and eval its init. Homebrew already provides every other
# CLI binary this config uses (eza, bat, fd, fzf, zoxide, atuin, navi, delta,
# vivid), so this is now consistent with the rest — and `brew upgrade` handles
# updates instead of `zinit update`.

#------------------------------------------------------------------------------
# 2. Helper functions
#------------------------------------------------------------------------------
# Everything here is named by an ice in section 4 (atinit/atload) or by a
# zstyle in section 3. Definitions must precede those references.

# --- compinit -----------------------------------------------------------------
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

# --- bracketed paste ----------------------------------------------------------
# Referenced by the two zstyles in section 3, which OMZP::safe-paste consumes.
# See the rationale attached to those zstyles — the pair is not optional.
_zsh_paste_init() {
  # widgets[self-insert] reads like "user:autosuggest-widget-self-insert";
  # [2,3] strips the "user:" tag and keeps the function name.
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}
_zsh_paste_finish() { zle -N self-insert $OLD_SELF_INSERT }

# --- fzf-git.sh rebind --------------------------------------------------------
# Named by fzf-git.sh's atload in section 4. Runs immediately after the plugin
# sources, i.e. after its own bindkey calls, so it can undo them. See the
# rationale on the FZF_GIT_PREFIX assignment in section 3.
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

#------------------------------------------------------------------------------
# 3. Plugin configuration
#------------------------------------------------------------------------------
# Every variable and zstyle a plugin reads AT SOURCE TIME. All of it must be in
# place before section 4 runs — which is now guaranteed by file order rather
# than by each assignment happening to sit above its own plugin.
#
# NOT here: FAST_WORK_DIR (fast-syntax-highlighting's state dir). It lives in
# .zshrc because it is a path into ~/.config that the theme steps in install.sh
# also reference; see the comment there.

# --- forgit -------------------------------------------------------------------
# Rename the 5 helpers whose default names collide with our own git shortcuts —
# which live in zsh/abbreviations, not aliases.zsh: ga, gd, grh, grs, gco. The
# f-prefixed names give the interactive versions; the plain names stay as the
# abbreviations.
#
# The collision is real even though one side is an abbreviation and the other an
# alias, and it is the confusing kind: zsh-abbr binds SPACE only (plus ^SPACE
# for a literal space) — it does not touch Enter. So `grs<space>` expands to
# `git reset --soft `, while a bare `grs<enter>` never expands and runs forgit's
# alias instead. One name, two behaviours, picked by whether you hit space.
# Renaming forgit's side keeps each name meaning exactly one thing.
forgit_add=fga
forgit_diff=fgd
forgit_reset_head=fgrh
forgit_restore=fgrs
forgit_checkout_commit=fgco

# forgit pagers. forgit resolves its pager as $FORGIT_PAGER → `git config
# core.pager` → `cat`, and core.pager is deliberately unset in .gitconfig (see
# the comment above the [delta] section there), so without this every forgit
# diff and show renders as raw `git diff --color=always` output — no delta, and
# so nothing matching the fzf-tab git previews in .zshrc, which do pipe through
# delta. Pointing forgit at delta makes the two agree.
#
# FORGIT_PREVIEW_PAGER is separate and NOT optional here: inside an fzf preview
# there is no TTY, and delta's own paging would otherwise engage and hang the
# pane. It overrides every other FORGIT_*_PAGER in preview context only.
#
# Must be exported, not just set — git-forgit is a separate bash process. The
# plugin exports stray FORGIT_* vars for us on load, but only with a warning.
export FORGIT_PAGER='delta'
export FORGIT_PREVIEW_PAGER='delta --paging=never'

# Directory previews (gcf on a directory, gwt/gwa on a worktree path). forgit
# defaults to `tree` (declared in the Brewfile, so it would be used) and falls
# back to `find` only when that is missing. eza instead — not because tree is
# absent, but because eza is what every other listing here goes through, so it
# picks up EZA_COLORS/LS_COLORS and the same Nerd Font icons. Swap it back to
# 'tree -C -L 2' if you prefer tree's output; both work.
#
# --icons=always, not the bare --icons used in aliases.zsh: forgit invokes this
# as `eval "$FORGIT_DIR_VIEW \"$path\""`, so the path lands immediately after
# the last flag and eza's optional-value parser eats it as --icons' argument
# ("invalid value 'themes' for --icons"). The = form pins the value.
export FORGIT_DIR_VIEW='eza --tree --level=2 --color=always --icons=always'

# --- auto-notify --------------------------------------------------------------
# Only ping for commands slower than the threshold, and never for
# interactive/long-lived TUIs we run in the foreground on purpose.
export AUTO_NOTIFY_THRESHOLD=20
export AUTO_NOTIFY_IGNORE=(nvim hx micro vim man less ssh tmux fzf navi \
  yazi ranger nnn xplr lazygit gitui btop htop top watch tail)

# --- abbr ---------------------------------------------------------------------
# fish-style abbreviations that expand inline as you type. Unlike an alias, the
# *expanded* command is what runs and what lands in history — pairs well with
# you-should-use. Manage with `abbr add ga='git add'`, `abbr list`, `abbr
# erase`. Definitions are seeded in $DOTFILES/zsh/abbreviations (pointed at
# below); abbr reads/writes that file directly so runtime `abbr add`s stay
# version-controlled.
export ABBR_USER_ABBREVIATIONS_FILE="$DOTFILES/zsh/abbreviations"

# --- safe-paste ---------------------------------------------------------------
# On zsh >= 5.1 (this is 5.9.2) the plugin collapses to three lines — it re-sets
# the zle_bracketed_paste option and swaps zsh's *built-in* bracketed-paste
# widget for bracketed-paste-magic. Worth being precise about what that buys,
# because it is not the obvious thing: the built-in widget already stops a
# pasted newline from auto-executing. What the magic widget adds is running
# pasted text through ZLE widgets, so url-quote-magic (URL escaping) applies to
# a paste instead of being bypassed.
#
# That processing is per-character, and per-character is exactly the case
# zsh-autosuggestions documents as "slow pasting" — every pasted char would
# otherwise re-enter the autosuggest self-insert wrapper, and with
# fast-syntax-highlighting also hooked in, a large paste crawls. The two zstyles
# below are upstream's own fix: swap self-insert to a bare url-quote-magic for
# the duration of the paste, then restore whatever widget was there. Without
# them this plugin is a net LOSS on this config — do not add one without the
# other, and do not move them below section 4.
autoload -Uz url-quote-magic
zstyle :bracketed-paste-magic paste-init   _zsh_paste_init
zstyle :bracketed-paste-magic paste-finish _zsh_paste_finish

# --- fzf-git.sh ---------------------------------------------------------------
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
# Change the prefix in one place here; _fzf_git_rebind in section 2 reads it.
FZF_GIT_PREFIX='^X^G'

#------------------------------------------------------------------------------
# 4. Plugin loading
#------------------------------------------------------------------------------
# The only section that calls `zinit`. Every block uses the `zinit <ices> for
# <plugins>` form — NOT the `zinit ice <ices>` + `zinit light <plugin>` pair
# this file used to mix in for the four single-plugin cases (nvm, carapace,
# fzf-git.sh, zsh-bench). Both forms work, but the two-step one is a live
# footgun: ices are consumed by the *next* zinit command, so inserting any
# zinit call — or a `zinit light` that is commented out mid-debug — between the
# `ice` and its `light` silently applies the ices to the wrong plugin, with no
# error. The `for` form binds ices to plugin names positionally and cannot come
# apart that way.
#
# Block order is load-bearing and must not be reshuffled:
#   1. zsh-nvm            — nothing depends on it; first so it is queued early
#   2. zsh-completions    — extra completion definitions, before compinit runs
#   3. fzf-tab            — its atinit runs compinit ONCE (zsh_compinit) so
#      autosuggestions      completions exist before fzf-tab hooks them
#      fast-syntax-highlighting — MUST be last of the three
#   4. carapace           — after 3, so compdef exists by the time it runs
#   5. behaviour plugins  — order-independent among themselves
#   6. fzf-git.sh
#   7. zsh-bench          — a program, not a plugin

# --- Node ---------------------------------------------------------------------
# zsh-nvm with lazy loading (NVM_LAZY_LOAD=true, set in .zprofile): the heavy
# nvm.sh is never sourced at startup. The plugin instead defines function shims
# for node/npm/npx/nvm that source it on first call.
#
# nvm is the ONLY node version manager here. asdf used to be declared in the
# Brewfile alongside it, but it had zero plugins installed and was never
# initialised in any shell file, so it managed nothing — it has been removed
# rather than wired up.
#
# The previous version of this comment claimed nvm managed no versions and that
# `node` therefore resolved to Homebrew's. Both halves are now wrong:
# ~/.nvm/versions/node holds v26.5.0, and ~/.nvm/alias/default is `node` — nvm's
# symbolic alias for "newest installed", not a literal version. This comment said
# `lts` until the alias files were actually read: ~/.nvm/alias/lts is an empty
# file, so had default really pointed there it would resolve to nothing. The
# v26.5.0 conclusion was right regardless, because `node` and the sole installed
# version coincide — but it held by luck, not by the mechanism described.
#
# So in an interactive shell `node` is the shim *function* and gives v26.5.0 — a
# function outranks any $path lookup, so Homebrew's v26.7.0 does not win despite
# /opt/homebrew/bin being first in the path array. Homebrew's node is what
# non-interactive shells and scripts get, since they never load this plugin.
# Verify with `whence -w node` in a real interactive shell — NOT `zsh -i -c`,
# which exits before the first prompt and so before turbo fires.
#
# Python — pyenv was removed. It managed zero versions (~/.pyenv/versions empty,
# `pyenv global` was `system`), so its shims and turbo-deferred `pyenv init`
# resolved python3 to the same Homebrew python they'd have hit anyway. If
# per-project Python versions are ever needed, add pyenv back here — or reach
# for mise and let one tool cover Node and Python together.
zinit wait lucid for \
  lukechilds/zsh-nvm

# --- Completions, fzf-tab, autosuggestions, syntax highlighting ---------------
# blockf on zsh-completions: don't let it push its own entry onto $fpath.
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
# used to live here. Registered per-command ON PURPOSE:
#
#   source <(carapace _carapace zsh)   # DON'T — one compdef hijacks 653 commands
#   source <(carapace gh zsh)          # scoped: emits `compdef _gh_completion gh`
#
# The wholesale form would take over `git`, `ssh`, `man`, `tar`, `find`… clobbering
# zsh's native _git and, with it, the `:completion:*:git-checkout:*` /
# `:fzf-tab:complete:git-(add|diff|…)` zstyles in .zshrc — those match on _git's
# sub-context, which _carapace_completer never produces. Add a line per tool that
# genuinely lacks a good native completion; leave the rest to zsh.
#
# Attached to the null plugin because there is no repo to clone — this is a pair
# of subprocesses, not a plugin. Deferred via turbo so they land after the first
# prompt, and ordered after the block above so compdef exists by the time they run.
zinit wait lucid id-as'carapace-init' has'carapace' \
  atload'source <(carapace gh zsh); source <(carapace pnpm zsh)' for \
  zdharma-continuum/null

# --- Extra behaviour plugins --------------------------------------------------
#   - OMZP::sudo          — ESC ESC prepends `sudo` to the current line (or the
#                           last command, on an empty line). Self-contained: it
#                           pulls no OMZ lib. ^X^X is pay-respects' inline fixer
#                           and ^X^E is edit-command-line — no collision.
#   - OMZP::safe-paste    — bracketed-paste-magic; see the zstyles in section 3,
#                           which are not optional.
#   - zsh-autopair        — auto-insert/delete matching brackets, quotes, parens
#   - zsh-you-should-use  — nags when a full command has an existing alias
#   - forgit              — fzf-powered git (glo, gss, gcb…); honours delta,
#                           and is put on $PATH so `git forgit <cmd>` works
#   - zsh-auto-notify     — desktop notification when a long command finishes
#                           (uses terminal-notifier, installed via Homebrew)
#   - zsh-abbr            — fish-style abbreviations; store is section 3's
#                           $ABBR_USER_ABBREVIATIONS_FILE
#
# forgit's atload is what makes the `git forgit …` sub-command work: forgit
# ships bin/git-forgit, and git finds a `git-<x>` on $PATH as sub-command <x>.
# Only the shell functions are wired up without it — which left the completion
# in place for a command that did not exist, since zinit already symlinks
# forgit's completions/_git-forgit into its own completions dir (on $fpath).
# `typeset -U path` in .zprofile keeps a re-source from duplicating the entry.
#
# With it, forgit is also reachable through git aliases, e.g.
#   git config --global alias.cf 'forgit checkout_file'
# and from non-interactive/bash contexts that never load this plugin file.
zinit wait lucid for \
  OMZP::sudo \
  OMZP::safe-paste \
  hlissner/zsh-autopair \
  MichaelAquilina/zsh-you-should-use \
  atload'path+=( "$FORGIT_INSTALL_DIR/bin" )' \
    wfxr/forgit \
  MichaelAquilina/zsh-auto-notify \
  olets/zsh-abbr

# --- fzf-git.sh ---------------------------------------------------------------
# fzf widgets that INSERT a git object into the line you are already typing:
# files, branches, tags, remotes, hashes, stashes, reflogs, each_ref, worktrees.
# Complements forgit above rather than overlapping it — forgit gives whole
# interactive *commands* (fga/fgd/glo), this gives *completions* mid-command,
# e.g. `git rebase -i <^X^G h>`. Previews use bat and delta, both already here.
# The ^G collision and the rebind live in sections 3 and 2 respectively.
zinit wait lucid for \
  has'fzf' pick'fzf-git.sh' atload'_fzf_git_rebind' \
    junegunn/fzf-git.sh

# --- zsh-bench (a program, not a plugin) --------------------------------------
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
zinit wait lucid for \
  as"program" pick"zsh-bench" \
    romkatv/zsh-bench
