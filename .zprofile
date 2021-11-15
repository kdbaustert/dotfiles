export CLICOLOR=1
export DOTFILES=$HOME/dotfiles
export EXA_ICON_SPACING=2
export EXA_GRID_ROWS=4
export LSCOLORS="Gxfxcxdxbxegedabagacad"
export EDITOR='nvim'
export VISUAL=$EDITOR
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;' # sane moving between words on the prompt
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:$HOME/.composer/vendor/bin"

export GPG_TTY=$(tty)

eval "$(/opt/homebrew/bin/brew shellenv)"
