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
# These four were missing the `cd` that every other entry in this block has, so
# they expanded to a bare path and the shell tried to *execute* the directory.
# The inner single quotes matter for the two paths containing a space: $HOME is
# expanded now, at definition time, and the quotes survive into the alias body.
alias vscode="cd '$HOME/Library/Application Support/Code'"
alias icloud="cd '$HOME/Library/Mobile Documents'"
alias cnc-claims="cd '$HOME/Development/cnc-claims'"
alias claimsource="cd '$HOME/Development/cnc-claimsource'"

alias caliases="code $DOTFILES/zsh/aliases.zsh"
alias chammerspoon="code $HOME/.hammerspoon/init.lua"
alias czshrc="code $HOME/.zshrc"
alias cspacebar="code $HOME/.spacebarrc"
alias cnvims="code $HOME/.config/nvim"
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

# ClamAV
# Signatures auto-update every 2h via ~/Library/LaunchAgents/com.clamav.freshclam.plist
# (StartInterval=7200, RunAtLoad). That symlink had gone missing, so nothing was
# updating them at all — re-linked and re-bootstrapped 2026-08-05.
#
# clamd is NOT running (`brew services list` reports clamav "none"), so the three
# clamdscan aliases below — clamq, clamdl, clamreload — currently fail with
# "Can't connect to clamd through .../clamd.sock". The clamscan-based ones work
# regardless, since they load signatures per invocation. Start the daemon with
# `brew services start clamav` if you want the fast path; note clamd holds the
# whole signature set resident (~1GB+).

# Scanning
alias clamf=clamfull                              # full-disk scan (function, see functions.zsh)
alias clamq='clamdscan --fdpass -m -i'            # quick scan via daemon — `clamq ~/Downloads`
alias clamdl='clamdscan --fdpass -m -i "$HOME/Downloads"'
# --fdpass is not optional: clamd runs as $USER, so without the passed file
# descriptor it can't open much of anything outside your own files.

# Signatures
alias clamdb='freshclam'                          # update signatures now
alias clamdbauto='launchctl kickstart gui/501/com.clamav.freshclam'  # trigger the scheduled update
alias clamdbinfo='sigtool --info /opt/homebrew/var/lib/clamav/daily.cvd | head -5'

# Daemon
alias clamon='brew services start clamav'
alias clamoff='brew services stop clamav'
alias clamrestart='brew services restart clamav'
alias clamstatus='brew services info clamav'
alias clamreload='clamdscan --reload'             # re-read signatures without a restart

# Logs
alias clamlog='tail -f "$HOME/clamav-full-scan.log"'
alias clamdblog='tail -20 /opt/homebrew/var/log/clamav/freshclam.log'
alias clamdlog='tail -20 /opt/homebrew/var/log/clamav/clamd.log'
alias clamcfg='command clamconf | head -40'       # dump effective config

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
# CGSession is gone: Apple removed the "Menu Extras" bundle that carried it, so
# the old path fails outright on macOS 26. pmset needs no Accessibility grant
# (the osascript Ctrl-Cmd-Q route fails silently without one) and locks straight
# away here, since `sysadminctl -screenLock status` reports an immediate delay.
alias lock='pmset displaysleepnow'
# macOS ships no /sbin/poweroff (that's a Linux/systemd name) — only halt,
# shutdown and reboot. `shutdown -h now` is the faithful equivalent.
alias poweroff='sudo /sbin/shutdown -h now'

# Removes all node_modules folders older than 4 months:
alias cnodeold='find . -name "node_modules" -type d -mtime +120 | xargs rm -rf'

# Removes all node_modules folders:
alias cnodeall='find . -name "node_modules" -type d | xargs rm -rf'

# Valet — moved to abbreviations (zsh/abbreviations)

# PHP Artisan — `phpa` moved to abbreviations (zsh/abbreviations)

# SSH
alias sshconfig='cd ~/.ssh; code config'
alias sshkeygen='ssh-keygen -t ed25519'
alias copyssh='ssh-copy-id -i ~/.ssh/github_1p.pub'
alias chmodssh='sudo chmod 700 ~/.ssh && chmod 600 ~/.ssh/*'

alias permission='chmod +x'

# Get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update='brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; composer global update; zinit update'

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
# NB: `brew` used to be aliased to strip pyenv's shims out of PATH first (they
# shadowed Homebrew's python and broke some formulae). pyenv is gone, so the
# alias is both unnecessary and actively broken — `$(pyenv root)` is evaluated
# on every use and would now fail. Don't reintroduce it.

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
