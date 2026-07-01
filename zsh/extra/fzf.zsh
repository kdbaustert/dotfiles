#!/bin/bash

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
--color=dark
--color=fg:250,fg+:15,hl:203,hl+:203
--color=info:100,pointer:15,marker:220,spinner:11,header:-1,gutter:-1,prompt:15
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
