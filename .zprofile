# export LS_COLORS=$(vivid generate ayu)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export COLORTERM="truecolor"
export TERM="xterm-256color"
export DOTFILES=$HOME/dotfiles
# export EXA_COLORS="ur=35;nnn:gr=35;nnn:tr=35;nnn:uw=34;nnn:gw=34;nnn:tw=34;nnn:ux=36;nnn:ue=36;nnn:gx=36;nnn:tx=36;nnn:uu=36;nnn:uu=38;5;235:da=38;5;238"
export EXA_ICON_SPACING=1
export EXA_GRID_ROWS=5
export EXA_COLUMNS=80 exa
export LSCOLORS=ExFxBxDxCxegedabagacad
export EDITOR='nvim'
export VISUAL=$EDITOR
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
export PYENV_ROOT="$HOME/.pyenv"
export GPG_TTY=$(tty)
export NTL_RUNNER=yarn
export NVM_COLORS='cmgRY'
export PATH="$PATH:$HOME/.spicetify"
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

source /Users/kenny/.zi/plugins/tj---git-extras/etc/git-extras-completion.zsh

if [ -d "$HOME/.composer/vendor/bin" ]; then
  export PATH="$HOME/.composer/vendor/bin:$PATH"
fi

if [ -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
fi

if [[ -z "$TMUX" ]]; then
  export TERM="xterm-256color"
fi

export PATH="/usr/local/mysql/bin:$PATH"
