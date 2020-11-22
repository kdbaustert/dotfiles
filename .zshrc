#! /bin/zsh

export DOTFILES=$HOME/dotfiles

# Locale.
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export TERM=xterm-256color
export ZSH_EXTEND_HISTORY_FILE=$DOTFILES/.zsh_extended_history
export PATH=$HOME/tools/nvim:$PATH
export PATH="$HOME/.npm-packages/bin:$PATH"
export NVM_DIR="$HOME/.nvm"

# Darwin
if [[ $OSTYPE == "darwin"* ]]; then
	export PATH="$PATH:$HOME/.composer/vendor/bin"
	export SSH_KEY_PATH="~/.ssh/id_rsa"
	export PATH="/usr/local/opt/ruby/bin:$PATH"
	export PATH=$PATH:$(ruby -e 'puts Gem.bindir')
	export PATH="/usr/local/sbin:$PATH"
fi

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

# ZINIT (PLUGIN MANAGER)
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
	print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
	command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
	command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" &&
		print -P "%F{33}▓▒░ %F{34}Installation successful.%f" ||
		print -P "%F{160}▓▒░ The clone has failed.%f"
fi

source "$HOME/.zinit/bin/zinit.zsh"

zinit load zsh-users/zsh-history-substring-search
zinit load zsh-users/zsh-completions
zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit snippet PZT::modules/history
zinit snippet PZT::modules/directory
zinit snippet PZT::modules/ssh

zinit light-mode for \
	gretzky/auto-color-ls \
	zpm-zsh/colors \
	djui/alias-tips \
	b4b4r07/enhancd \
	zsh-users/zsh-autosuggestions \
	zdharma/fast-syntax-highlighting \
	Aloxaf/fzf-tab

# FZF-TAB
zinit ice wait"1" lucid
zinit light Aloxaf/fzf-tab

zinit load lincheney/fzf-tab-completion
zinit load wookayin/fzf-fasd

zinit light-mode for \
	zdharma/fast-syntax-highlighting \
	zsh-users/zsh-autosuggestions

# ls colors
zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
	atpull'%atclone' pick"clrs.zsh" nocompile'!' \
	atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

zstyle ':prezto:module:ssh:load' identities 'id_rsa'

# Enable completions
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

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
setopt COMPLETEALIASES # complete alisases
setopt AUTOMENU

# syntax color definition
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

autoload colors && colors

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

#THEFUCK
eval "$(thefuck --alias)"

# COMPLETION
[[ -f $DOTFILES/zsh/completion.zsh ]] && source $DOTFILES/zsh/completion.zsh

[[ -f $DOTFILES/zsh/p10k.zsh ]] && source $DOTFILES/zsh/p10k.zsh

# FZF SETTINGS
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview="cat {}" --preview-window=right:60%:wrap'
export FZF_ALT_C_OPTS='--preview="ls {}" --preview-window=right:60%:wrap'
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--height=50%
--color=fg:#e5e9f0,bg:'rgb(0,0,0,0)',hl:#60fdff
--color=fg+:#e5e9f0,bg+:'rgb(0,0,0,0)',hl+:#60fdff
--color=info:#6871ff,prompt:#6871ff,pointer:#00b0ff
--color=marker:#6871ff,spinner:#00b0ff,header:#6871ff'

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
	dir # current directory
	vcs # git status
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

source $(brew --prefix nvm)/nvm.sh

# neofetchs