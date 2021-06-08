# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Created by Kenny B <kenny@gothamx.dev>

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
  command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" &&
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" ||
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
    zinit-zsh/z-a-rust \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

zinit ice depth=1; zinit light romkatv/powerlevel10k

#####################
# PLUGINS           #
#####################

# SSH-AGENT
zinit light bobsoppe/zsh-ssh-agent

# AUTOSUGGESTIONS, TRIGGER PRECMD HOOK UPON LOAD
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
zinit ice wait'0a' lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

# Then load url-quote-magic and bracketed-paste-magic as above
autoload -U url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

# Now the fix, setup these two hooks:
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}


zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# and finally, make sure zsh-autosuggestions does not interfere with it:
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(expand-or-complete bracketed-paste accept-line push-line-or-edit)

# ENHANCD
zinit ice wait'0b' lucid
zinit light b4b4r07/enhancd
export ENHANCD_FILTER=fzf:fzy:peco
zinit light zsh-users/zsh-history-substring-search

# TAB COMPLETIONS
zinit light-mode for \
    blockf \
        zsh-users/zsh-completions \
    as'program' atclone'rm -f ^(rgg|agv)' \
        lilydjwg/search-and-view \
    atclone'dircolors -b LS_COLORS > c.zsh' atpull'%atclone' pick'c.zsh' \
        trapd00r/LS_COLORS \
    src'etc/git-extras-completion.zsh' \
        tj/git-extras
zinit wait'1' lucid for \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/git.zsh \
    OMZ::plugins/systemd/systemd.plugin.zsh \
    OMZ::plugins/gpg-agent/gpg-agent.plugin.zsh \
    OMZ::plugins/command-not-found/command-not-found.plugin.zsh \

zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*:descriptions' format '-- %d --'
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:complete:*:options' sort false
zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'  # disable for tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-pad 0 0
zstyle ':completion:*:git-checkout:*' sort false

zinit ice lucid wait'0b' from'gh-r' as'program'
zinit light junegunn/fzf

# FZF TMUX HELPER SCRIPT
zinit ice lucid wait'0c' as'command' pick'bin/fzf-tmux'
zinit light junegunn/fzf

# BIND MULTIPLE WIDGETS USING FZF
zinit ice lucid wait'0c' multisrc'shell/{completion,key-bindings}.zsh' id-as'junegunn/fzf_completions' pick'/dev/null'
zinit light junegunn/fzf

# FZF-TAB
zinit ice wait'1' lucid
zinit light Aloxaf/fzf-tab

# SYNTAX HIGHLIGHTING
zinit ice wait'0c' lucid atinit'zpcompinit;zpcdreplay'
zinit light zdharma/fast-syntax-highlighting

# ZSH DIFF SO FANCY
zinit ice wait'2' lucid as'program' pick'bin/git-dsf'
zinit light zdharma/zsh-diff-so-fancy

# neovim
zinit wait'0' lucid \
  id-as'nvim' from'gh-r' ver'nightly' as'program' pick'nvim*/bin/nvim' \
  atclone'echo "" > ._zinit/is_release' \
  atpull'%atclone' \
  run-atpull \
  atload'alias v=nvim' \
  light-mode for @neovim/neovim

# GH-CLI
zinit ice lucid wait'0' as'program' id-as'gh' from'gh-r' has'git' \
  atclone'./gh completion -s zsh > _gh' atpull'%atclone' mv'**/bin/gh -> gh'
zinit light cli/cli

# prettyping
zinit ice wait lucid as'program' mv'prettyping* -> prettyping' \
    atload"alias ping='prettyping --nolegend'"
zinit light denilsonsa/prettyping

# bottom system monitor
zinit ice from'gh-r' ver'nightly' as'program' id-as'bottom' \
  atclone'echo "" > ._zinit/is_release' \
  atpull'%atclone' \
  atload'alias top=btm' \
  atload'alias htop=btm'
zinit light ClementTsang/bottom

zinit light-mode for \
  gretzky/auto-color-ls \
  MichaelAquilina/zsh-you-should-use \

zinit ice wait'1' lucid
zinit light laggardkernel/zsh-thefuck

export NVM_LAZY_LOAD=true
zinit light lukechilds/zsh-nvm

#####################
# HISTORY           #
#####################
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zhistory"
HISTSIZE=290000
SAVEHIST=$HISTSIZE

#####################
# SETOPT            #
#####################
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data
setopt completealiases        # complete alisases
setopt automenu
setopt autocd
setopt sharehistory           # global history

#####################
# ENV VARIABLE      #
#####################
export EDITOR='nvim'
export VISUAL=$EDITOR
export DOTFILES=$HOME/dotfiles
export SHELL='/bin/zsh'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'  # sane moving between words on the prompt
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export GEM_HOME="$HOME/.gem"
export PROMPT_EOL_MARK=''  # hide % at end of output
export PATH=$HOME/bin:$PATH

#####################
# COLORING          #
#####################
autoload colors && colors

#####################
# FANCY-CTRL-Z      #
#####################
function fg-fzf() {
  job="$(jobs | fzf -0 -1 | sed -E 's/\[(.+)\].*/\1/')" && echo '' && fg %$job
}

function fancy-ctrl-z () {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER=" fg-fzf"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}

zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

#####################
# FZF SETTINGS      #
#####################
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview="bat --color=always --style=header {} 2>/dev/null" --preview-window=right:60%:wrap'
export FZF_ALT_C_COMMAND='fd -t d -d 1'
export FZF_ALT_C_OPTS='--preview="exa -1 --icons --git --git-ignore {}" --preview-window=right:60%:wrap'
bindkey '^F' fzf-file-widget

# FZF custom OneDark theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--ansi
--height=50%
--color=fg:-1,bg:-1,border:#4B5164,hl:#d19a66
--color=fg+:#f7f7f7,bg+:#2c323d,hl+:#e5c07b
--color=info:#828997,prompt:#e06c75,pointer:#45cdff
--color=marker:#98c379,spinner:#e06c75,header:#98c379'

# FZF options for zoxide prompt (zi)
export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS'
--height=7'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

[[ -f $DOTFILES/zsh/p10k.zsh ]] && source $DOTFILES/zsh/p10k.zsh

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