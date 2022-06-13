# Fig pre block. Keep at the top of this file.
. "$HOME/.fig/shell/zprofile.pre.zsh"
# export LS_COLORS=$(vivid generate ayu)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export COLORTERM="truecolor"
export DOTFILES=$HOME/dotfiles
export EXA_COLORS="ur=35;nnn:gr=35;nnn:tr=35;nnn:uw=34;nnn:gw=34;nnn:tw=34;nnn:ux=36;nnn:ue=36;nnn:gx=36;nnn:tx=36;nnn:uu=36;nnn:uu=38;5;235:da=38;5;238"
export EXA_ICON_SPACING=1
export EXA_GRID_ROWS=5
export EXA_COLUMNS=80 exa
export LSCOLORS=ExFxBxDxCxegedabagacad
export EDITOR='nvim'
export VISUAL=$EDITOR
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export GPG_TTY=$(tty)
export NTL_RUNNER=yarn
export NVM_COLORS='cmgRY'
export PATH="$PATH:$HOME/.spicetify"
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"
export PNPM_HOME="/Users/kenny/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
# export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/bzip2/lib"
# export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/bzip2/include"

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

# Fig post block. Keep at the bottom of this file.
. "$HOME/.fig/shell/zprofile.post.zsh"
export PATH="/usr/local/mysql/bin:$PATH"
