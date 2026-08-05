#!/usr/bin/env zsh

#######################################
# FZF deserves its own config         #
# Don't move it to zsh_config.zsh     #
#######################################

# Common fd command
FD="fd --hidden --follow --strip-cwd-prefix"

# Default TUI options
export FZF_DEFAULT_OPTS="
--multi
--keep-right
--no-mouse
--prompt '⯈ '
--marker=+
--preview-window='right:hidden:wrap'
# Voltage (themes/voltage.md), matching ghostty / starship / LS_COLORS / bat /
# delta. Hex rather than the 256 indices this used before: the old codes (203,
# 220, 100…) were approximations that drifted from every other tool. bg:-1 and
# gutter:-1 keep the terminal's own background showing through, so fzf doesn't
# paint a slightly-off panel over the blur.
--color=fg:#e7e7e7,fg+:#f8f8f8,bg:-1,bg+:#2a2427
--color=hl:#eb43f4,hl+:#f712ff
--color=info:#b3e053,prompt:#ff4d5e,pointer:#5cc9f5
--color=marker:#fcf58d,spinner:#17d5df,header:#17d5df
--color=border:#6b6b6b,gutter:-1
--layout=reverse
--height=60%
--border=rounded
"

# Default command to run to generate search entries
export FZF_DEFAULT_COMMAND="$FD --type f --type l"

# Command for `CTRL-T`
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Used for generating completions for `path`
# Ex: vim **<tab> runs _fzf_compgen_path()
_fzf_compgen_path() {
  eval "$FZF_DEFAULT_COMMAND -- $1"
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
