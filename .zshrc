export DOTFILES=$HOME/dotfiles

# EXPORTS
[[ -f $DOTFILES/zsh/exports.zsh ]] && source $DOTFILES/zsh/exports.zsh

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

# source $HOME/fzf-tab-completion/zsh/fzf-zsh-completion.sh

setopt AUTO_CD       # Auto changes to a directory without typing cd.
setopt AUTO_PUSHD    # Push the old directory onto the stack on cd.
setopt EXTENDED_GLOB # Use extended globbing syntax.
setopt PUSHD_TO_HOME # Push to home directory when no argument is given.

# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
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

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]/}

# --------------------
# Module configuration
# --------------------

#
# completion
#

# Set a custom path for the completion dump file.
# If none is provided, the default ${ZDOTDIR:-${HOME}}/.zcompdump is used.
#zstyle ':zim:completion' dumpfile "${ZDOTDIR:-${HOME}}/.zcompdump-${ZSH_VERSION}"

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=10'

# ------------------
# Initialize modules
# ------------------

if [[ ${ZIM_HOME}/init.zsh -ot $DOTFILES/zsh/.zimrc ]]; then
  # Update static initialization script if it's outdated, before sourcing it
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
source ${ZIM_HOME}/init.zsh

[[ -f $DOTFILES/zsh/p10k.zsh ]] && source $DOTFILES/zsh/p10k.zsh

#
#zsh-history-substring-search
#

# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Bind up and down keys
zmodload -F zsh/terminfo +p:terminfo
if [[ -n ${terminfo[kcuu1]} && -n ${terminfo[kcud1]} ]]; then
  bindkey ${terminfo[kcuu1]} history-substring-search-up
  bindkey ${terminfo[kcud1]} history-substring-search-down
fi

bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
# }}} End configuration added by Zim install

# SSH
zstyle ':zim:ssh' ids 'id_rsa' 'github'

# THEFUCK
eval "$(thefuck --alias)"

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
# POWERLEVEL9K_DIR_ETC_FOREGROUND=#00b0ff
# POWERLEVEL9K_RAM_FOREGROUND=#5ffa68
# POWERLEVEL9K_LOAD_NORMAL_FOREGROUND=#00b0ff
# POWERLEVEL9K_LOAD_WARNING_FOREGROUND=#fffc58
# POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND=#fa2b73
# POWERLEVEL9K_LARAVEL_VERSION_FOREGROUND=#fa2b73
# POWERLEVEL9K_STATUS_OK_FOREGROUND=#5ffa68
# POWERLEVEL9K_STATUS_ERROR_FOREGROUND=#fa2b73
# POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=#fffc58

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


# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

neofetch
