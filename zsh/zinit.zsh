### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
  command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" &&
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" ||
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "${HOME}/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit ice depth=1; zinit light romkatv/powerlevel10k

# SSH-AGENT
zinit light bobsoppe/zsh-ssh-agent

zinit ice wait'1' lucid
zinit light laggardkernel/zsh-gpg-agent

# zinit ice lucid nocompile wait'0e' nocompletions
# zinit load MenkeTechnologies/zsh-more-completions

zinit ice wait blockf lucid atpull'zinit creinstall -q .'
zinit light https://github.com/zsh-users/zsh-completions

# zinit ice lucid nocompile
# zinit load MenkeTechnologies/zsh-expand

zinit ice wait lucid atinit'ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay' \
  atload'unset "FAST_HIGHLIGHT[chroma-whatis]" "FAST_HIGHLIGHT[chroma-man]"'
zinit light https://github.com/zdharma/fast-syntax-highlighting

zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light https://github.com/zsh-users/zsh-autosuggestions

zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
atpull'%atclone' pick"clrs.zsh" nocompile'!' \
atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

zinit ice wait"!0" blockf lucid pick"init.sh"
zinit light "b4b4r07/enhancd"

zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

zinit wait'1' lucid for \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/git.zsh \
    OMZ::plugins/command-not-found/command-not-found.plugin.zsh \
    OMZ::plugins/history/history.plugin.zsh \
    zpm-zsh/ssh \
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
zinit ice wait"1b" lucid as"program" pick"bin/git-dsf"
zinit light zdharma/zsh-diff-so-fancy

# fuzzy git
# https://github.com/wfxr/forgit
zinit ice has'fzf'
zinit light wfxr/forgit

# ─── fuzzy movement and directory choosing ────────────────────────────────────
# autojump command
# https://github.com/rupa/z
zinit ice wait'0c' lucid
zinit light rupa/z

# Pick from most frecent folders with `Ctrl+g`
# https://github.com/andrewferrier/fzf-z
: zinit ice wait'0b' lucid
: zinit load andrewferrier/fzf-z

# lets z+[Tab] and zz+[Tab]
# https://github.com/changyuheng/fz
zinit ice wait'0b' lucid
zinit light changyuheng/fz

# sharkdp/fd
zinit ice as"program" from"gh-r" mv"fd* -> fd" pick"fd/fd"
zinit light sharkdp/fd

# FZF-TAB
zinit ice wait'1' lucid
zinit light Aloxaf/fzf-tab

zinit light-mode for \
  gretzky/auto-color-ls \
  MichaelAquilina/zsh-you-should-use \

zinit ice wait'1' lucid
zinit light laggardkernel/zsh-thefuck

export NVM_LAZY_LOAD=true
zinit light lukechilds/zsh-nvm
