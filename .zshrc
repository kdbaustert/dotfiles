export DOTFILES=$HOME/dotfiles
fpath=(~/.local/share/zsh/comp $fpath)
setopt promptsubst

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

zinit light-mode for \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-bin-gem-node

zinit for \
		light-mode	zsh-users/zsh-history-substring-search \
        light-mode  zsh-users/zsh-autosuggestions \

zinit snippet PZT::modules/directory/init.zsh
zinit snippet PZT::modules/history/init.zsh
zinit snippet PZT::modules/ssh/init.zsh
zinit snippet PZT::modules/osx/init.zsh

zinit ice wait'0' atinit"zpcompinit" lucid
zinit light zdharma/fast-syntax-highlighting

zinit load zsh-users/zsh-completions

zinit light-mode for \
        gretzky/auto-color-ls \
		zpm-zsh/colors \
		djui/alias-tips \
		b4b4r07/enhancd \

zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

zinit load changyuheng/zsh-interactive-cd

# ls colors
zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
    atpull'%atclone' pick"clrs.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

zinit load lincheney/fzf-tab-completion
zinit load wookayin/fzf-fasd

zinit light Aloxaf/fzf-tab

zinit ice depth=1
zinit light romkatv/powerlevel10k

# Activate completion
if type brew &>/dev/null; then
	FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

	autoload -Uz compinit
	compinit
fi

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

# zstyle ':completion:*' menu select
# zstyle ':completion:*:warnings' format '%F{red}no matches found%f'

# # complete environment variables
# zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# # # correct single char typos
# zstyle ':completion:*' completer _complete _match _approximate
# zstyle ':completion:*:match:*' original only
# zstyle ':completion:*:approximate:*' max-errors 1 numeric

zstyle ":completion:*:git-checkout:*" sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-command fzf

# syntax color definition
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

#THEFUCK
eval "$(thefuck --alias)"
eval "$(fasd --init auto)"

[[ -f $DOTFILES/zsh/completion.zsh ]] && source $DOTFILES/zsh/completion.zsh

[[ -f $DOTFILES/zsh/p10k.zsh ]] && source $DOTFILES/zsh/p10k.zsh

# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# #eval `dircolors`
# zstyle ':completion:*:default' list-colors ${LS_COLORS}
# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

autoload colors && colors

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

neofetch

# export NVM_DIR="$HOME/.nvm"
# [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
