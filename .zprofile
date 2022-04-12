# export CLICOLOR=1
export DOTFILES=$HOME/dotfiles
# ANSI quotes not single quotes needed here for \
export PS3=$'\e[1;34m-->>>> \e[0m'
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR="YES"
export LSCOLORS="ExFxBxDxCxegedabagacad"
export EXA_ICON_SPACING=1
export EXA_GRID_ROWS=5
export EXA_COLUMNS=80 exa
export LSCOLORS=ExFxBxDxCxegedabagacad
export EDITOR='nvim'
export VISUAL=$EDITOR
export LANG='en_US.UTF-8'
export LC_ALLs='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$PATH:$HOME/.composer/vendor/bin"
export GPG_TTY=$(tty)
export NTL_RUNNER=yarn
# export NVM_COLORS='cmgRY'
export PATH="$PATH:$HOME/.spicetify"
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"
export PATH=/usr/local/clamav/bin:/usr/local/clamav/sbin:$PATH
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=`which chromium`

if [[ -z "$TMUX" ]]; then
	export TERM="xterm-256color"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(pyenv init --path)"
