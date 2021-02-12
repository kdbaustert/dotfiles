if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOTFILES=$HOME/dotfiles
export LANG=en_US.UTF-8
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export TERM=xterm-256color
export NVM_DIR="$HOME/.nvm"
export PATH="$PATH:$HOME/.composer/vendor/bin"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export GEM_HOME="$HOME/.gem"

# Use modern completion system
# zstyle ':completion:*' menu select
# zstyle ':completion:*' matcher-list '' \
#     'm:{a-z\-}={A-Z\_}' \
#     'r:[^[:alpha:]]|[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
#     'r:[^[:ascii:]]|[[:ascii:]]=** r:|=* m:{a-z\-}={A-Z\_}'
# zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
# zstyle ':completion:*' format $'\n%F{yellow}Completing %d%f\n'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*:functions' ignored-patterns '_*'

# define FZF params
export COLORTERM="truecolor"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=180'
export FZF_BASE=/usr/bin/fzf
export FZF_DEFAULT_OPTS=' --color=light '
export FZF_DEFAULT_COMMAND='rg --files'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ZINIT (PLUGIN MANAGER)
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
  command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
  command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" &&
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f" ||
    print -P "%F{160}▓▒░ The clone has failed.%f"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit ice depth=1
zinit light romkatv/powerlevel10k

setopt correct
setopt correct_all
setopt extendedglob

zinit light zdharma/history-search-multi-word

zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

zinit ice lucid wait pick:"fzf-tab.zsh"
zinit load "Aloxaf/fzf-tab"

zinit ice atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh" nocompile'!'
zinit light trapd00r/LS_COLORS

zinit light xav-b/zsh-extend-history
export ZSH_EXTEND_HISTORY_FILE="$HOME/.zsh_extended_history"

zinit snippet OMZL::directories.zsh
zinit snippet OMZP::ssh-agent
zinit snippet OMZP::history
zinit snippet OMZP::colorize
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::autojump
zinit snippet OMZP::fancy-ctrl-z
zinit snippet OMZP::fasd
zinit snippet OMZP::safe-paste
zinit snippet OMZL::clipboard.zsh
zinit snippet OMZP::gitignore

# load ssh
zstyle :omz:plugins:ssh-agent identities id_rsa

zinit wait lucid for OMZP::git
zinit wait lucid for rupa/z

zinit light-mode for \
		zpm-zsh/colors \
		djui/alias-tips \
		gretzky/auto-color-ls \
		b4b4r07/enhancd \
		MichaelAquilina/zsh-you-should-use \
		wfxr/forgit \
		aperezdc/zsh-fzy

zinit light chrissicool/zsh-256color

export NVM_LAZY_LOAD=true
zinit light lukechilds/zsh-nvm

zinit light hlissner/zsh-autopair

# auto completions
autoload -Uz compinit
compinit -c
zstyle ':completion:*' menu select

# load these plugins last
zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

[[ -f $DOTFILES/zsh/p10k.zsh ]] && source $DOTFILES/zsh/p10k.zsh

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

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
setopt COMPLETEALIASES
setopt AUTOMENU
setopt AUTOCD

zstyle ":history-search-multi-word" page-size "30"

# autoload -U colors && colors
# export SPROMPT="Correct $fg[red]%R$reset_color to $fg[green]%r?$reset_color (Yes, No, Abort, Edit) "

# zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# zstyle ':fzf-tab:*' continuous-trigger '/'
# zstyle ':completion:*:descriptions' format
# zstyle ':fzf-tab:*' show-group full

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
	nvm
	# =========================[ Line #2 ]=========================
	newline
)

FZF_DEFAULT_OPTS='--height 50% --ansi'
FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

#THEFUCK
eval "$(thefuck --alias)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
