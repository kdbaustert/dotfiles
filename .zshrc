export DOTFILES=$HOME/dotfiles
fpath=(~/.local/share/zsh/comp $fpath)

# EXPORTS
[[ -f $DOTFILES/zsh/exports.zsh ]] && source $DOTFILES/zsh/exports.zsh

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh


# ZINIT (PLUGIN MANAGER)
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f" || \
        print -P "%F{160}▓▒░ The clone has failed.%f"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit load g-plane/zsh-yarn-autocompletions

zinit for \
		load	zsh-users/zsh-history-substring-search \
    light-mode  zsh-users/zsh-autosuggestions \
    light-mode  zdharma/fast-syntax-highlighting \
                zdharma/history-search-multi-word \
# load completions
autoload -Uz compinit && compinit -C
zinit cdreplay -q

zinit ice depth=1; zinit light romkatv/powerlevel10k

zinit snippet PZT::modules/history
zinit snippet PZT::modules/directory
zinit snippet PZT::modules/ssh

zinit light-mode for \
    gretzky/auto-color-ls \
		zpm-zsh/colors \
		djui/alias-tips \
		b4b4r07/enhancd \

zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

zinit wait lucid atload"zicompinit; zicdreplay" blockf for zsh-users/zsh-completions

zstyle ':prezto:module:ssh:load' identities 'id_rsa'

# options
setopt AUTO_CD       # Auto changes to a directory without typing cd.
setopt AUTO_PUSHD    # Push the old directory onto the stack on cd.
setopt EXTENDED_GLOB # Use extended globbing syntax.
setopt PUSHD_TO_HOME # Push to home directory when no argument is given.

# Correct commands.
setopt CORRECT

#
# History
#
HISTSIZE=1000000
SAVEHIST=1000000

setopt HIST_IGNORE_ALL_DUPS
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_SAVE_NO_DUPS
setopt COMPLETEALIASES        # complete alisases
setopt AUTOMENU
# SSH

# zstyle :omz:plugins:ssh-agent lifetime 4h

# syntax color definition
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

#THEFUCK
eval "$(thefuck --alias)"

[[ -f $DOTFILES/zsh/p10k.zsh ]] && source $DOTFILES/zsh/p10k.zsh

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 補完候補にも色付き表示
#eval `dircolors`
zstyle ':completion:*:default' list-colors ${LS_COLORS}
# kill の候補にも色付き表示
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'


POWERLEVEL9K_BACKGROUND='transparent'
POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_beginning"
POWERLEVEL9K_VCS_SHORTEN_LENGTH=4
POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH=5
POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''

# POWERLEVEL9K_OS_ICON_FOREGROUND=255
POWERLEVEL9K_ICON_BEFORE_CONTENT=false
# POWERLEVEL9K_DIR_FOREGROUND=#03F7F7
# POWERLEVEL9K_DIR_DEFAULT_FOREGROUND=#03F7F7
# POWERLEVEL9K_DIR_HOME_FOREGROUND=#03F7F7
# POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND=#03F7F7
POWERLEVEL9K_DIR_ETC_FOREGROUND=#00b0ff
POWERLEVEL9K_RAM_FOREGROUND=#5ffa68
POWERLEVEL9K_LOAD_NORMAL_FOREGROUND=#00b0ff
POWERLEVEL9K_LOAD_WARNING_FOREGROUND=#fffc58
POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND=#fa2b73
POWERLEVEL9K_LARAVEL_VERSION_FOREGROUND=#fa2b73
POWERLEVEL9K_STATUS_OK_FOREGROUND=#5ffa68
POWERLEVEL9K_STATUS_ERROR_FOREGROUND=#fa2b73
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=#fffc58

# POWERLEVEL9K_DIR_CLASSES=()

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
	# =========================[ Line #1 ]=========================
	os_icon # os identifier
	context
	dir     # current directory
	vcs     # git status
	# =========================[ Line #2 ]=========================
	newline     # \n
	prompt_char # prompt symbol
)

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
	# =========================[ Line #1 ]=========================
	status                 # exit code of the last command
	command_execution_time # duration of the last command
	laravel_version        # laravel php framework version
	node_version           # node.js version
	ram                    # free RAM
	load                   # CPU load
	php_version            # php version (https://www.php.net/)
	# =========================[ Line #2 ]=========================
	newline
)

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

neofetch

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' insert-unambiguous false
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' \
'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=**' \
'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=** l:|=*'
zstyle ':completion:*' max-errors 2
zstyle ':completion:*' menu select=1
zstyle ':completion:*' original true
zstyle ':completion:*' select-prompt %SScrlling active: current selection at %p%s
zstyle ':completion:*' verbose true
zstyle ':completion:*' completer _complete _ignored
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
