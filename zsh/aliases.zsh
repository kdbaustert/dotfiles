#!/usr/bin/env zsh

# Shortcuts
# `c` and `x` belong to composer and xplr further down this file; they used to be
# declared here as clear/exit too and were silently shadowed, since a second
# `alias` on the same name just replaces the first.
alias cl='clear'
alias o='open .'
alias q='exit'
alias x+="chmod +x"
# `copyssh` lives in the SSH block below (ssh-copy-id). The clipboard-copy
# variant that used to sit here was shadowed by it anyway, and `pkey`/`pubkey`
# already cover copying the public key.
alias reload="source ~/.zshrc"
# `pbcopy` is macOS's, and on Linux it is a function defined in
# zsh/os/linux-interactive.zsh that forwards to wl-copy or xclip. Keeping the
# macOS name as the portable one — rather than inventing a `clipcopy` both
# platforms have to learn — is what lets these two lines, and pkey/pubkey
# below, stay here unbranched.
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias genpass='LC_ALL=C tr -dc "[:alnum:]" < /dev/urandom | head -c 20 | pbcopy'
# Exact -name, not '*.DS_Store': the glob also matches any real file whose name
# merely ends in .DS_Store (a `notes.DS_Store` in a test tree was deleted by it),
# and this one runs as root, so an over-match is unrecoverable.
alias cleandotfiles="sudo find . -type f -name '.DS_Store' -ls -delete"
alias claude-clean='for d in backups cache file-history projects session-env; do rm -rf "$HOME/.claude/$d"/*(N) "$HOME/.claude/$d"/.[!.]*(N) 2>/dev/null; done; echo "Cleared ~/.claude/{backups,cache,file-history,projects,session-env}"'
alias ngroka='ngrok config add-authtoken'
alias ngrok='ngrok http --url=engaged-obviously-ferret.ngrok-free.app 80'


# Directories
alias desk="cd ~/desktop"
alias docs="cd ~/documents"
alias dev="cd $HOME/Development"
alias sites="cd $HOME/Sites"
alias dl="cd $HOME/Downloads"
alias dotfiles="cd $HOME/dotfiles"
# `phpdir`, `vscode` and `icloud` name platform-specific directories and moved
# to zsh/os/$DOTFILES_OS-interactive.zsh; the two below are the same path on
# both machines and stay here.
#
# These were missing the `cd` that every other entry in this block has, so they
# expanded to a bare path and the shell tried to *execute* the directory. The
# inner single quotes matter for a path containing a space: $HOME is expanded
# now, at definition time, and the quotes survive into the alias body.
alias cnc-claims="cd '$HOME/Development/cnc-claims'"
alias claimsource="cd '$HOME/Development/cnc-claimsource'"

alias caliases="code $DOTFILES/zsh/aliases.zsh"
alias czshrc="code $HOME/.zshrc"
alias cnvims="code $HOME/.config/nvim"

# History search (atuin)
alias ms='atuin search -i'
alias msm='atuin search'

# Common aliases
alias x="xplr"
alias xcd='cd "$(xplr)"'
alias rdir='rm -rf'
alias rfile='rm'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias wget='wget -c'
alias mkcd=mcd
alias v="nvim"
alias nvmini="NVIM_APPNAME=mini nvim"
alias lg="lazygit"

if which eza &>/dev/null; then
  alias ls='eza --icons --classify'
  alias l='eza -a -lgmH --icons -G'
  alias la='l -@'
  alias ll='l -h'
  alias l1='eza -1 --group-directories-first'
  alias la1='l1 -a'
  alias le='eza -a -lgH -s extension --group-directories-first'
  alias lm='eza -a -lghH -s modified -m'
  alias lu='eza -a -lghH -s modified -uU'
  alias lt='eza -T'
  alias llt='eza -a -lgHh -R -T'
  alias tree='llt'
  alias lr='eza -a -lgHh -R -L 2'
  alias lrr='eza -a -lgHh -R'
else
  # Fallback only — eza is in the Brewfile and is what actually runs here. Now
  # lsd-only on purpose: most of these aliases used to call `colorls`, a Ruby gem
  # that is not installed and not in the Brewfile, so if eza ever did go missing
  # this branch would have handed back mostly command-not-found. Deliberately
  # smaller than the eza set above — only the names with a faithful lsd
  # equivalent, rather than approximations that behave subtly differently.
  alias ls='lsd'
  alias l='lsd -A --group-dirs first'
  alias la='lsd -a'
  alias ll='lsd -lA --group-dirs first'
  alias lla='lsd -la'
  alias l1='lsd -1 --group-dirs first'
  alias la1='lsd -1a --group-dirs first'
  alias lt='lsd --tree'
  alias llt='lsd -lA --tree'
  alias tree='lsd --tree'
  alias lr='lsd -lA --tree --depth 2'
fi

# Retargeted from ~/.ssh/id_rsa.pub, which does not exist on this machine (nor
# does a private id_rsa). ~/.ssh/config pins github_1p.pub for github.com via the
# 1Password agent, so that is the key you actually hand out.
alias pkey="pbcopy < ~/.ssh/github_1p.pub"
alias pubkey="pbcopy < ~/.ssh/github_1p.pub && echo '=> Public key copied to pasteboard.'"

# Power, session and OS-maintenance commands (lock, reboot, poweroff, the DNS
# cache flush, the LaunchServices rebuild, the volume mute) are all the same
# idea reached through completely different tools on each platform, so they live
# in zsh/os/$DOTFILES_OS-interactive.zsh rather than as if/else pairs here.

# Removes all node_modules folders older than 4 months:
alias cnodeold='find . -name "node_modules" -type d -mtime +120 | xargs rm -rf'

# Removes all node_modules folders:
alias cnodeall='find . -name "node_modules" -type d | xargs rm -rf'

# PHP Artisan — `phpa` moved to abbreviations (zsh/abbreviations)

# SSH
alias sshconfig='cd ~/.ssh; code config'
alias sshkeygen='ssh-keygen -t ed25519'
alias copyssh='ssh-copy-id -i ~/.ssh/github_1p.pub'
alias chmodssh='sudo chmod 700 ~/.ssh && chmod 600 ~/.ssh/*'

alias permission='chmod +x'

# `update` is the system package manager plus the language ones, so its first
# three commands differ entirely per platform — see the OS interactive files.

# Recursively remove .DS_Store files. Kept portable rather than filed under
# macOS: a shared drive or a repo touched by a Mac carries these onto Linux too,
# and `find -delete` is the same on both.
alias dsnuke="find . -name '*.DS_Store' -type f -ls -delete"

# `chromekill` matches on the macOS helper-process name and moved to the OS
# files; the Linux renderer processes are named differently.

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# Brew — subcommands moved to abbreviations (zsh/abbreviations); `brewf`/`ibrew`
# moved to zsh/os/macos-interactive.zsh.
# NB: `brew` used to be aliased to strip pyenv's shims out of PATH first (they
# shadowed Homebrew's python and broke some formulae). pyenv is gone, so the
# alias is both unnecessary and actively broken — `$(pyenv root)` is evaluated
# on every use and would now fail. Don't reintroduce it.

# FZF
alias hist="history | fzf"
alias f="fzf"

# Node.js — npm prefixes moved to abbreviations (zsh/abbreviations)
alias npmc='npm install & composer install'

#PNPM — prefixes moved to abbreviations (zsh/abbreviations)
alias pug="pnpm list -g --json | jq '.[] | .dependencies | keys | .[]' -r  | xargs pnpm add -g"

# Git — prefixes moved to abbreviations (zsh/abbreviations). These stay as
# aliases: abbr names can't hold ! or ~, and gwip/gui are compound.
alias gc!="git commit --amend --no-edit"
alias gca!="git commit -a --amend --no-edit"
alias gcam!="git commit -a --amend"
alias gcm!="git commit --amend"
alias gd~="git diff HEAD~"
alias gr~="git reset HEAD~"
alias gui="gitui"
alias gwip!="git add --all && git commit -a --amend --no-edit"
alias gwip="git add --all && git commit -am 'WIP'"

# Git Large Storage
alias gitli='git lfs install'
alias gitlt='git lfs track'

# Composer — subcommands moved to abbreviations (zsh/abbreviations)
alias c='composer'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

alias ziu='zi update --all'
alias zic='zi cclear'
