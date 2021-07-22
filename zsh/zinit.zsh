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

 zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
    atpull'%atclone' pick"clrs.zsh" nocompile'!' atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
  zinit light https://github.com/trapd00r/LS_COLORS


  zinit ice wait blockf lucid atpull'zinit creinstall -q .'
  zinit light https://github.com/zsh-users/zsh-completions

  zinit ice wait lucid atinit'ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay' \
    atload'unset "FAST_HIGHLIGHT[chroma-whatis]" "FAST_HIGHLIGHT[chroma-man]"'
  zinit light https://github.com/zdharma/fast-syntax-highlighting

  zinit ice wait lucid atload'_zsh_autosuggest_start'
  zinit light https://github.com/zsh-users/zsh-autosuggestions

zinit ice wait"!0" blockf lucid pick"init.sh"
zinit light "b4b4r07/enhancd"

zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin

# SSH-AGENT
zinit light bobsoppe/zsh-ssh-agent
zinit light rhuang2014/gpg-agent
zinit light chrissicool/zsh-256color

zinit light "marzocchi/zsh-notify"

zinit wait'1' lucid for \
    OMZ::lib/clipboard.zsh \
    OMZ::lib/git.zsh \
    OMZ::plugins/command-not-found/command-not-found.plugin.zsh \

# fzf-marks, at slot 0, for quick Ctrl-G accessibility
# https://github.com/urbainvaes/fzf-marks
zinit ice trackbinds bindmap'^g -> ^f' lucid
zinit light urbainvaes/fzf-marks

# ─── fuzzy movement and directory choosing ────────────────────────────────────
# autojump command
# https://github.com/rupa/z
zinit ice wait'0c' lucid
zinit light rupa/z

# Pick from most frecent folders with `Ctrl+g`
# https://github.com/andrewferrier/fzf-z
# : zinit ice wait'0b' lucid
# : zinit load andrewferrier/fzf-z

# lets z+[Tab] and zz+[Tab]
# https://github.com/changyuheng/fz
# zinit ice wait'0b' lucid
# zinit light changyuheng/fz

# # sharkdp/fd
# zinit ice as"program" from"gh-r" mv"fd* -> fd" pick"fd/fd"
# zinit light sharkdp/fd

# # sharkdp/bat
# zinit ice as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
# zinit light sharkdp/bat

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