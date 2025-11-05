# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh"
emulate sh
source ~/.profile
emulate zsh

# export LS_COLORS=$(vivid generate ayu)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export COLORTERM="truecolor"
export TERM="xterm-256color"
export DOTFILES=$HOME/dotfiles
# export EXA_COLORS="ur=35;nnn:gr=35;nnn:tr=35;nnn:uw=34;nnn:gw=34;nnn:tw=34;nnn:ux=36;nnn:ue=36;nnn:gx=36;nnn:tx=36;nnn:uu=36;nnn:uu=38;5;235:da=38;5;238"
export EZA_ICON_SPACING=1
export EZA_GRID_ROWS=5
export EZA_COLUMNS=80 exa
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
export HOMEBREW_BREWFILE=$HOME/.brewfile
export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH
export PATH="$HOME/.config/composer/vendor/bin:$PATH"
export PATH="/Users/kenny/Library/Electron/alias:$PATH"
#export PATH=$PATH:/Users/kenny/.spicetify

# export PATH="/opt/homebrew/opt/unzip/bin:$PATH"
# export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

# source /Users/kenny/.zi/plugins/tj---git-extras/etc/git-extras-completion.zsh

# Intel macs
#if [ -d "$HOME/.composer/vendor/bin" ]; then
#export PATH="$HOME/.config/composer/vendor/bin:$PATH"
#fi

# M1 Macs
# if [ -d "$HOME/.config/composer/vendor/bin:$PATH" ]; then
#   export PATH="$HOME/.config/composer/vendor/bin:$PATH"
# fi

# if command -v ngrok &>/dev/null; then
# 	eval "$(ngrok completion)"
# fi

if [ -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
fi

if [[ -z "$TMUX" ]]; then
  export TERM="xterm-256color"
fi

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh"
