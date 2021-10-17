export CLICOLOR=1
export DOTFILES=$HOME/dotfiles
export LSCOLORS="Gxfxcxdxbxegedabagacad"
export EDITOR='nvim'
export VISUAL=$EDITOR
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;' # sane moving between words on the prompt
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:~/.local/bin" # for pipx
export PATH="/usr/local/sbin:$PATH"

GPG_TTY=$(tty)

if test -f ~/.gnupg/.gpg-agent-info -a -n "$(pgrep gpg-agent)"; then
  export GPG_AGENT_INFO
  GPG_TTY=$(tty)
  export GPG_TTY
else
  eval $(gpg-agent --daemon ~/.gnupg/.gpg-agent-info)
fi
