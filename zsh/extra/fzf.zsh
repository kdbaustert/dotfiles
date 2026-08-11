#!/usr/bin/env zsh

#######################################
# FZF deserves its own config         #
# Don't move it to zsh_config.zsh     #
#######################################

# Common fd command. --color=always makes fd tint each entry by file type from
# $LS_COLORS, so the pickers agree with eza and the completion menu instead of
# listing everything in flat white. The pickers pair it with --ansi, which
# renders those escapes and strips them from the value fzf prints — what lands
# on the command line is still a clean path.
FD="fd --hidden --follow --strip-cwd-prefix --color=always"

# Default TUI options
export FZF_DEFAULT_OPTS="
--multi
--keep-right
--no-mouse
# NB: this string is double-quoted, so comment lines in it are still subject to
# expansion. Keep them free of dollar signs and backticks -- a backticked
# command name here is run as a command substitution when this file is sourced,
# which hangs the shell on an invisible fzf reading the terminal.
#
# --ansi renders the LS_COLORS escapes fd emits, and strips them from the value
# fzf prints, so completions still insert clean paths. It has to be global
# rather than scoped to the CTRL-T/ALT-C/completion wrappers: a bare fzf (the
# f alias) inherits the colorized default command too, and without --ansi it
# prints the escapes literally, wrecking both the color and the column
# alignment. CTRL-R opts back out below.
--ansi
--prompt '⯈ '
--marker=+
# The preview pane. This window was configured here long before anything filled
# it: with no --preview command and no toggle bind, it could never be shown or
# populated. bat renders files through the Voltage theme (see BAT_THEME in
# .zshrc), eza covers directories -- which is what ALT-C lists -- and the bare
# echo is the fallback for input that is not a path at all, such as the hist
# alias piping shell history in. Without that last arm those previews print an
# eza error instead of the line.
#
# It stays hidden by default, so the cost is only paid when it is toggled on.
--preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || eza -1 --color=always --icons=always --group-directories-first {} 2>/dev/null || echo {}'
--preview-window='right:hidden:wrap'
# Both spellings: Ctrl-/ is what you press, but most terminals transmit it as
# 0x1F, which fzf names ctrl-_. Binding only one of the two leaves the pane
# unreachable on whichever terminal disagrees.
--bind=ctrl-/:toggle-preview,ctrl-_:toggle-preview
# Voltage (themes/voltage.md), matching ghostty / starship / LS_COLORS / bat /
# delta. Hex rather than the 256 indices this used before: the old codes (203,
# 220, 100…) were approximations that drifted from every other tool. bg:-1 and
# gutter:-1 keep the terminal's own background showing through, so fzf doesn't
# paint a slightly-off panel over the blur.
#
# fg+ does not clobber the per-file ANSI colors on the current line — fzf layers
# item color over the base — so the row under the cursor keeps its file-type
# tint and only picks up the bg+ fill.
--color=fg:#e7e7e7,fg+:#f8f8f8,bg:-1,bg+:#2a2427,gutter:-1
--color=hl:#eb43f4,hl+:#f712ff
# Marked rows (--multi). Previously only the marker glyph distinguished them;
# selected-bg gives the row itself a fill, one step darker than the cursor's
# bg+ so the two stay tellable apart.
--color=selected-fg:#e7e7e7,selected-bg:#1c191a,selected-hl:#f712ff
--color=info:#b3e053,prompt:#ff4d5e,pointer:#5cc9f5,query:#f8f8f8
# marker was #fcf58d, which is an EZA_COLORS extra rather than a palette entry;
# bright yellow is the documented slot.
--color=marker:#f8f079,spinner:#17d5df,header:#17d5df
--color=border:#6b6b6b,separator:#393a3d,scrollbar:#6b6b6b
--layout=reverse
--height=60%
--border=rounded
"

# Default command to run to generate search entries
export FZF_DEFAULT_COMMAND="$FD --type f --type l"

# Command for `CTRL-T` (paste path) and `ALT-C` (cd into dir). ALT-C needs an
# explicit command: left unset, fzf falls back to its own built-in directory
# walker, which knows nothing about LS_COLORS and would list flat white next to
# the other two pickers.
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="$FD --type d"

# CTRL-R opts back out of the global --ansi. History entries are raw command
# text, so parsing them as ANSI would swallow any escape sequence a stored
# command legitimately contains. fzf resolves duplicate options in favour of the
# later one, and the shell integration appends $FZF_CTRL_R_OPTS after
# $FZF_DEFAULT_OPTS, so this wins.
export FZF_CTRL_R_OPTS="--no-ansi"

# Used for generating completions for `path`
# Ex: vim **<tab> runs _fzf_compgen_path()
# Reads $FD rather than $FZF_DEFAULT_COMMAND: fzf's completion wrapper runs
# `unset FZF_DEFAULT_COMMAND` in the subshell *before* invoking this hook, so
# expanding it here yields `eval " -- ./"` and the completion dies with
# "command not found: --". $FD survives because it's a plain shell variable of
# the interactive shell, which the subshell inherits — same as _fzf_compgen_dir.
_fzf_compgen_path() {
  eval "$FD --type f --type l -- $1"
}

# Used for generating completions for `directory`
# Ex: cd **<tab> runs _fzf_compgen_dir()
_fzf_compgen_dir() {
  eval "$FD --type d -- $1"
}

# Alias picker (Alt-A) — fuzzy-search every alias, insert the chosen name onto
# the command line. The expansion is shown in the preview pane so you can see
# what it resolves to before committing. Ctrl-Space toggles inserting the full
# expansion instead of the alias name.
_fzf_alias_widget() {
  local pick col
  # `alias` prints  name='expansion' — split on the first '=' into name<TAB>expansion.
  pick=$(alias | sed 's/=/\t/' | \
    fzf --height=45% --layout=reverse --delimiter='\t' --with-nth=1 \
        --prompt='alias ⯈ ' \
        --preview='echo {2}' --preview-window='down:3:wrap' \
        --expect=ctrl-space) || return
  # First line = key pressed (empty for Enter), second line = selected row.
  col=1; [[ ${pick%%$'\n'*} == ctrl-space ]] && col=2
  pick=${pick#*$'\n'}
  [[ -z $pick ]] && return
  # Strip surrounding quotes from the expansion when inserting column 2.
  local out=$(print -r -- "$pick" | cut -f$col)
  (( col == 2 )) && out=${out#\'} && out=${out%\'}
  LBUFFER+="$out "
  zle reset-prompt
}
zle -N _fzf_alias_widget
bindkey '^[a' _fzf_alias_widget   # Alt-A
