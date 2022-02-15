# Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
  command git clone https://github.com/zdharma-continuum/zinit.git "$HOME/.zinit/bin" &&
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" ||
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "${HOME}/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=

# SSH-AGENT
zinit light bobsoppe/zsh-ssh-agent

#####################
# PROMPT            #
#####################
zinit lucid for \
    as"command" from"gh-r" atload'eval "$(starship init zsh)"' \
    starship/starship \

# IMPORTANT:
# Ohmyzsh plugins and libs are loaded first as some these sets some defaults which are required later on.
# Otherwise something will look messed up
# ie. some settings help zsh-autosuggestions to clear after tab completion

setopt promptsubst

# Explanation:
# - Loading tmux first, to prevent jumps when tmux is loaded after .zshrc
# - History plugin is loaded early (as it has some defaults) to prevent empty history stack for other plugins
zinit lucid for \
    atinit"
        export ZSH_TMUX_FIXTERM=false
        export ZSH_TMUX_AUTOSTART=false
        export ZSH_TMUX_AUTOCONNECT=true
        export ZSH_TMUX_DEFAULT_SESSION_NAME='</>'
    " \
    OMZP::tmux \
    atinit"HIST_STAMPS=dd.mm.yyyy" \
    OMZL::history.zsh \


zinit wait lucid for \
	OMZL::clipboard.zsh \
	OMZL::compfix.zsh \
	OMZL::completion.zsh \
	OMZL::correction.zsh \
    atload'
        alias ..="cd .."
        alias ...="cd ../.."
        alias ....="cd ../../.."
        alias .....="cd ../../../.."
        function take() {
            mkdir -p $@ && cd ${@:$#}
        }
        alias rm="rm -rf"
    ' \
	OMZL::directories.zsh \
	OMZL::git.zsh \
	OMZL::key-bindings.zsh \
	OMZL::termsupport.zsh \
    atload"
        alias gcd='git checkout dev'
        alias gce='git commit -a -e'
    " \
	OMZP::git \
    djui/alias-tips \
    https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh \
    https://github.com/junegunn/fzf/blob/master/shell/completion.zsh \

# IMPORTANT:
# These plugins should be loaded after ohmyzsh plugins

zinit wait lucid for \
    light-mode blockf atpull'zinit creinstall -q .' \
    atinit"
        zstyle ':completion:*' completer _expand _complete _ignored _approximate
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zstyle ':completion:*' menu select=2
        zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
        zstyle ':completion:*:descriptions' format '-- %d --'
        zstyle ':completion:*:processes' command 'ps -au$USER'
        zstyle ':completion:complete:*:options' sort false
        zstyle ':fzf-tab:complete:_zlua:*' query-string input
        zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm,cmd -w -w'
        zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
        zstyle ':fzf-tab:complete:cd:*' extra-opts --preview=$extract'exa -1 --color=always ${~ctxt[hpre]}$in'
    " \
        zsh-users/zsh-completions \
    light-mode atinit"ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20" atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    light-mode atinit"
        typeset -gA FAST_HIGHLIGHT;
        FAST_HIGHLIGHT[git-cmsg-len]=100;
        zpcompinit;
        zpcdreplay;
    " \
        zdharma-continuum/fast-syntax-highlighting \
        zdharma-continuum/history-search-multi-word \
				xav-b/zsh-extend-history

#####################
# PROGRAMS          #
#####################

zinit wait lucid light-mode as'command' for \
    from'gh-r' atinit'export PATH="$HOME/.yarn/bin:$PATH"' mv'yarn* -> yarn' pick"yarn/bin/yarn" bpick'*.tar.gz' \
        yarnpkg/yarn \

zinit wait"1a" lucid light-mode from"gh-r" as"command" for \
    atload'
        eval "$(zoxide init --no-aliases zsh)"
        alias z="__zoxide_z"
    ' mv'zoxide* -> zoxide' pick'zoxide/zoxide' \
        @ajeetdsouza/zoxide \
        @junegunn/fzf \
    mv'ripgrep* -> rg' pick'rg/rg' \
        @BurntSushi/ripgrep \
    mv'fd* -> fd' pick'fd/fd' \
        @sharkdp/fd \
    mv'bat* -> bat' pick'bat/bat' \
        @sharkdp/bat \
    mv'delta* -> delta' pick'delta/delta' \
        @dandavison/delta \
    atload'
        unalias l
        alias l="exa -abghHlS --git --group-directories-first"
    ' pick'bin/exa' \
        @ogham/exa \

# ENHANCD
zinit ice wait'0b' lucid
zinit light b4b4r07/enhancd
export ENHANCD_FILTER=fzf:fzy:peco

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
    OMZ::lib/git.zsh

if whence dircolors >/dev/null; then
  eval "$(dircolors -b)"
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  alias ls='ls --color'
else
  export CLICOLOR=1
  zstyle ':completion:*' list-colors ''
fi

zinit ice wait'1' lucid
zinit light Aloxaf/fzf-tab

zinit wait"2" lucid as"program" from"gh-r" for \
      mv"lsd-*/lsd -> lsd" atload"alias ls='lsd'" Peltoche/lsd

# # fzf - fuzzy finder
zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

# z - jump around
zinit wait lucid for \
	"agkozak/zsh-z"

# ─── fuzzy movement and directory choosing ────────────────────────────────────
# autojump command
# https://github.com/rupa/z
zinit ice wait'0c' lucid
zinit light rupa/z

zinit for \
    light-mode zpm-zsh/colors \
    light-mode laggardkernel/zsh-thefuck

export NVM_LAZY_LOAD=true
zinit light lukechilds/zsh-nvm
