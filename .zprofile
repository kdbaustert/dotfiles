#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####
export CLICOLOR=1
export DOTFILES=$HOME/dotfiles
export EXA_ICON_SPACING=1
export EXA_GRID_ROWS=5
export EXA_COLUMNS=80 exa
export LSCOLORS="uu=38;5;249:un=38;5;241:gu=38;5;245:gn=38;5;241:da=38;5;245:sn=38;5;7:sb=38;5;7:ur=38;5;3;1:uw=38;5;5;1:ux=38;5;1;1:ue=38;5;1;1:gr=38;5;249:gw=38;5;249:gx=38;5;249:tr=38;5;249:tw=38;5;249:tx=38;5;249:fi=38;5;248:di=38;5;253:ex=38;5;1:xa=38;5;12:*.png=38;5;4:*.jpg=38;5;4:*.gif=38;5;4"
export EDITOR='nvim'
export VISUAL=$EDITOR
export LANG='en_US.UTF-8'
export LC_ALLs='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=/usr/local/opt/python/libexec/bin:$PATH
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$PATH:$HOME/.composer/vendor/bin"
export TERM="xterm-256color"
export GPG_TTY=$(tty)
export XDEBUG_CONFIG="IDEKEY=VSCODE"
export NTL_RUNNER=yarn
export NVM_COLORS='cmgRY'

eval "$(/opt/homebrew/bin/brew shellenv)"
#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####

# Setting PATH for Python 3.10
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.10/bin:${PATH}"
export PATH

# Setting PATH for Python 3.10
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.10/bin:${PATH}"
export PATH
eval "$(pyenv init --path)"
