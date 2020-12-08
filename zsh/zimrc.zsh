# Start configuration added by Zim install {{{
# -------
# Modules
# -------

# Sets sane Zsh built-in environment options.
zmodule environment
# Provides handy git aliases and functions.
zmodule git
# Applies correct bindkeys for input events.
zmodule input
# Sets a custom terminal title.
zmodule termtitle
# Utility aliases and functions. Adds colour to ls, grep and less.
zmodule utility

#
# Prompt
#
# Exposes git repository status information to prompts.
zmodule git-info

zmodule romkatv/powerlevel10k

# Additional completion definitions for Zsh.
zmodule zsh-users/zsh-completions
# Enables and configures smart and extensive tab completion.
# completion must be sourced after zsh-users/zsh-completions
zmodule completion
# Fish-like autosuggestions for Zsh.
zmodule zsh-users/zsh-autosuggestions
# Fish-like syntax highlighting for Zsh.
# zsh-users/zsh-syntax-highlighting must be sourced after completion
zmodule zsh-users/zsh-syntax-highlighting
# Fish-like history search (up arrow) for Zsh.
# zsh-users/zsh-history-substring-search must be sourced after zsh-users/zsh-syntax-highlighting
zmodule zsh-users/zsh-history-substring-search
# }}} End configuration added by Zim install

zmodule ssh

zmodule gretzky/auto-color-ls
zmodule djui/alias-tips
zmodule b4b4r07/enhancd

zmodule zdharma/fast-syntax-highlighting
zmodule zsh-users/zsh-completions
zmodule zsh-users/zsh-autosuggestions
#zmodule Aloxaf/fzf-tab
#zmodule wookayin/fzf-fasd
zmodule zsh-users/zsh-history-substring-search
zmodule chrissicool/zsh-256color
