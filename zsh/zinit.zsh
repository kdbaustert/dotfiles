### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" &&
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" ||
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "${HOME}/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=

# Load starship theme
# zinit ice from"gh-r" as"program" atload'!eval $(starship init zsh)'
# zinit light starship/starship

# SSH-AGENT
zinit light bobsoppe/zsh-ssh-agent

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
    OMZ::lib/clipboard.zsh \
    OMZ::lib/git.zsh

if whence dircolors >/dev/null; then
  eval "$(dircolors -b)"
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  alias ls='ls --color'
else
  export CLICOLOR=1
  zstyle ':completion:*' list-colors ''
fi

zinit ice lucid wait'0c' as'command' pick'bin/fzf-tmux'
zinit light junegunn/fzf

# FZF-TAB

zinit ice wait'1' lucid
zinit light Aloxaf/fzf-tab

zinit wait lucid light-mode for \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" zdharma-continuum/fast-syntax-highlighting \
  blockf zsh-users/zsh-completions \
  atload"!_zsh_autosuggest_start; export ZSH_AUTOSUGGEST_USE_ASYNC=1" zsh-users/zsh-autosuggestions

#zinit lucid from'gh-r' as'program' for \
  #mv'zoxide* -> zoxide' atload'eval "$(zoxide init zsh)"' ajeetdsouza/zoxide \
  #mv'mcfly* -> mcfly' atload'eval "$(mcfly init zsh)"; export MCFLY_KEY_SCHEME=vim; export MCFLY_FUZZY=true' cantino/mcfly

zinit wait'1' lucid for \
    OMZP::command-not-found \
    OMZP::history \
    chrissicool/zsh-256color

zinit light xav-b/zsh-extend-history

zinit wait"2" lucid as"program" from"gh-r" for \
      mv"lsd-*/lsd -> lsd" atload"alias ls='lsd'" Peltoche/lsd

# prettyping
zinit ice wait lucid as'program' mv'prettyping* -> prettyping' \
    atload"alias ping='prettyping --nolegend'"
zinit light denilsonsa/prettyping

# fzf - fuzzy finder
zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

# z - jump around
zinit wait lucid for \
	"agkozak/zsh-z"

# diff-so-fancy
# https://github.com/so-fancy/diff-so-fancy
# zinit ice wait"1b" lucid as"program" pick"bin/git-dsf"
# zinit light zdharma/zsh-diff-so-fancy

# FORGIT
zinit ice wait lucid id-as'forgit' atload'alias gr=forgit::checkout::file'
zinit load 'wfxr/forgit'

# ─── fuzzy movement and directory choosing ────────────────────────────────────
# autojump command
# https://github.com/rupa/z
zinit ice wait'0c' lucid
zinit light rupa/z

# sharkdp/fd
zinit ice as"program" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zinit light sharkdp/fd

zinit ice wait'1' lucid
zinit light laggardkernel/zsh-thefuck

export NVM_LAZY_LOAD=true
zinit light lukechilds/zsh-nvm
