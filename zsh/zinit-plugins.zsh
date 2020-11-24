#! /bin/zsh

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

zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
    atpull'%atclone' pick"clrs.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

zinit snippet PZT::modules/history
zinit snippet PZT::modules/directory
zinit snippet PZT::modules/ssh

zinit ice wait lucid
zinit snippet OMZ::plugins/fzf/fzf.plugin.zsh

zinit light-mode for \
	gretzky/auto-color-ls \
	djui/alias-tips \
	b4b4r07/enhancd \

zinit ice wait'!0'; zinit load zdharma/fast-syntax-highlighting
zinit ice wait'!0'; zinit load zsh-users/zsh-completions

zinit ice as"completion"

zinit ice wait atload"_zsh_autosuggest_start" lucid
zinit load zsh-users/zsh-autosuggestions

# FZF-TAB
zinit ice wait"1" lucid
zinit light Aloxaf/fzf-tab

zinit load lincheney/fzf-tab-completion
zinit load wookayin/fzf-fasd

zinit load zsh-users/zsh-history-substring-search

zinit load chrissicool/zsh-256color

# zinit ice nocd lucid atload="!source $DOTFILES/zsh/p10k.zsh"
# zinit load romkatv/powerlevel10k

zinit ice depth=1; zinit light romkatv/powerlevel10k

zinit light buonomo/yarn-completion