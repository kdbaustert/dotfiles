#!/usr/bin/env zsh

# Shortcuts
alias c='clear'
alias o='open .'
alias x='exit'
alias x+="chmod +x"
alias copyssh="pbcopy < $HOME/.ssh/id_rsa.pub"
alias reload="source ~/.zshrc"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias search-history='$(history | cut -c8- | sort -u | pick)'
alias genpass='LC_ALL=C tr -dc "[:alnum:]" < /dev/urandom | head -c 20 | pbcopy'
alias purgemem='sudo purge'
alias clearDNSCache='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias cleandotfiles="find . -type f -name '*.DS_Store' -ls -delete"
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
alias phpdir="cd /opt/homebrew/etc/php"
alias vscode="$HOME/Library/Application Support/Code/"
alias icloud="$HOME/Library/Mobile\ Documents"
alias cnc-claims="$HOME/Development/cnc-claims"
alias claimsource="$HOME/Development/cnc-claimsource"

alias caliases="code $DOTFILES/aliases.zsh"
alias chammerspoon="code $HOME/.hammerspoon/init.lua"
alias cyabai="code $HOME/.yabairc"
alias czshrc="code $HOME/.zshrc"
alias cspacebar="code $HOME/.spacebarrc"
alias cnvims="code $HOME/.config/nvim/init.vim"
# alias valetconfig="code /usr/local/etc/nginx/valet/valet.conf"

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
  alias ls='lsd'
  alias la='ls -a'
  alias lla='ls -la'
  alias lt='ls --tree'
  alias ll='colorls --group-directories-first --almost-all --long'
  alias lc='colorls -lA --sd'
  alias l='colorls --group-directories-first --almost-all --tree=1'
  alias ll='colorls --group-directories-first --almost-all --long'
  alias ld='colorls --group-directories-first --almost-all --dirs --tree=1'
  alias lf='colorls --group-directories-first --almost-all --files --tree=1'
  alias lt1='colorls --group-directories-first --almost-all --tree=1'
fi

alias pkey="pbcopy < ~/.ssh/id_rsa.pub"
alias pubkey="more ~/.ssh/id_rsa.pub | pbcopy | echo '=> Public key copied to pasteboard.'"

# CLAMSCAN
alias clamf="sudo clamscan -r /"
alias claimdb="freshclam"

# MacOS commands
alias testspeed="networkQuality"

# Delete all screenshots from the Desktop
alias rmshots="find ~/Desktop -maxdepth 1 -type f \( -name 'Screenshot *.png' -o -name 'Screen Shot *.png' \) -print -delete"

# Fix LSD pegging the CPU
# https://discussions.apple.com/message/30186026#message30186026
alias fixlsd="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user ; killall Dock"
alias resetlsd=fixlsd

# computer power options
alias reboot='sudo /sbin/reboot'
alias shutdown='sudo /sbin/shutdown'
alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'
alias poweroff='sudo /sbin/poweroff'

# Removes all node_modules folders older than 4 months:
alias cnodeold='find . -name "node_modules" -type d -mtime +120 | xargs rm -rf'

# Removes all node_modules folders:
alias cnodeall='find . -name "node_modules" -type d | xargs rm -rf'

# Tiling window manager
alias yabres='brew services restart yabai && brew services restart skhd'
alias yabrestart='brew services start yabai && brew services start skhd'
alias yabrestop='brew services stop yabai && brew services stop skhd'
alias yabupdate='brew services stop yabai && brew upgrade yabai && sudo yabai --uninstall-sa && sudo yabai --install-sa && brew services start yabai'

# Valet — moved to abbreviations (zsh/abbreviations)

# PHP Artisan — `phpa` moved to abbreviations (zsh/abbreviations)

# SSH
alias sshconfig='cd ~/.ssh; code config'
alias sshkeygen='ssh-keygen -t rsa'
alias copyssh='ssh-copy-id -i ~/.ssh/id_rsa.pub'
alias chmodssh='sudo chmod 700 ~/.ssh && chmod 600 ~/.ssh/*'

alias permission='chmod +x'

# Get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update='brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; sudo gem update colorls; composer global update; zinit update'

# Recursively remove .DS_Store files
alias dsnuke="find . -name '*.DS_Store' -type f -ls -delete"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# 🔇
alias stfu="osascript -e 'set volume output muted true'"

# Brew — subcommands moved to abbreviations (zsh/abbreviations)
alias brewf='$(brew --prefix)'
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'

# FZF
alias hist="history | fzf"
alias f="fzf"

# WordPress — wp-cli commands moved to abbreviations (zsh/abbreviations).
# These stay as aliases: they point to shell functions, not commands.
alias newwp=install_wp
alias wp_ignore='wp_gitignore'

# Vue cli — moved to abbreviations (zsh/abbreviations)

# Node.js — npm prefixes moved to abbreviations (zsh/abbreviations)
alias npmc='npm install & composer install'

#PNPM — prefixes moved to abbreviations (zsh/abbreviations)
alias pug="pnpm list -g --json | jq '.[] | .dependencies | keys | .[]' -r  | xargs pnpm add -g"

# Yarn — moved to abbreviations (zsh/abbreviations)

# Nvm — moved to abbreviations (zsh/abbreviations)

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

# PHP code sniffer
alias codewp='phpcs --config-set default_standard WordPress'
alias codelaravel='phpcs --config-set default_standard Laravel'

alias ibrew='arch -x86_64 /usr/local/bin/brew'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

alias ziu='zi update --all'
alias zic='zi cclear'
