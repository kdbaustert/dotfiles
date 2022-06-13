#!/usr/bin

# Shourtcuts
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

# Directories
alias desk="cd ~/desktop"
alias docs="cd ~/documents"
alias dev="cd $HOME/Development"
alias sites="cd $HOME/Sites"
alias dl="cd $HOME/Downloads"
alias dotfiles="cd $HOME/dotfiles"
alias phpdir="cd /opt/homebrew/etc/php"

alias caliases="code $DOTFILES/aliases.zsh"
alias chammerspoon="code $HOME/.hammerspoon/init.lua"
alias cyabai="code $HOME/.yabairc"
alias czshrc="code $HOME/.zshrc"
alias czshrc="code $HOME/.spacebarrc"
alias cnvims="code $HOME/.config/nvim/init.vim"
# alias valetconfig="code /usr/local/etc/nginx/valet/valet.conf"

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

alias a='fasd -a'        # any
alias s='fasd -si'       # show / search / select
alias d='fasd -d'        # directory
alias f='fasd -f'        # file
alias sd='fasd -sid'     # interactive directory selection
alias sf='fasd -sif'     # interactive file selection
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
alias zz='fasd_cd -d -i' # cd with interactive selection

if which exa &>/dev/null; then
	alias ls='exa --icons --classify'
	alias l='exa -a -lgmH --icons -G'
	alias la='l -@'
	alias ll='l -h'
	alias l1='exa-1 --group-directories-first'
	alias la1='l1 -a'
	alias le='exa -a -lgH -s extension --group-directories-first'
	alias lm='exa -a -lghH -s modified -m'
	alias lu='exa -a -lghH -s modified -uU'
	alias lt='exa -T'
	alias llt='exa -a -lgHh -R -T'
	alias tree='llt'
	alias lr='exa -a -lgHh -R -L 2'
	alias lrr='exa -a -lgHh -R'
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

# Fix LSD pegging the CPU
# https://discussions.apple.com/message/30186026#message30186026
alias fixlsd="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.fram ework/Support/lsregister -kill -r -domain local -domain system -domain user ; killall Dock"
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

# Valet
alias vs='valet start'
alias vst='valet stop'
alias vls='valet links'
alias vl='valet link'
alias vul='valet unlink'
alias vssl='valet secure'

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

# Brew
alias brewl='brew list'
alias brewi='brew install'
alias brewri='brew reinstall'
alias brewr='brew remove'
alias brewcl='brew list --cask'
alias brewci='brew install --cask'
alias brewd='brew doctor'
alias brews='brew search'
alias brewsr='brew services restart'
alias brewsl='brew services list'

# FZF
alias hist="history | fzf"

# WordPress
alias wp_get_salts="curl https://api.wordpress.org/secret-key/1.1/salt/"
alias wp_export_staging='wp @staging db export - > "staging_db_$(date +%F_$R).sql"'
alias wp_export_production='wp @production db export - > "production_db_$(date +%F_$R).sql"'
alias newwp=install_wp
alias wp_core='wp core download'
alias new_wpconfig='wp config create'
alias newwpplugin='wp scaffold plugin'
alias wp_ignore='wp_gitignore'
alias wp_dbcheck='wp db check'
alias wp_repairdb='wp db repair'
alias wp_optimize='wp db optimize'
alias wp_child_theme='wp scaffold child-theme'
alias wp_update_plugins='wp plugin update --all'
alias wp_pages="wp post list --post_type='page'"

# Vue cli
alias vinspect='vue inspect'
alias vrules='vue inspect --rules'
alias vrule='vue inspect --rule $1'
alias vplugins='vue inspect --plugins'

# Node.js
alias npmgroot='npm root -g'
alias npmgl='npm list -g --depth 0'
alias npmg='npm install -g'
alias npmi='npm install'
alias npms='npm install --save'
alias npmsd='npm install --save-dev'
alias npmrw='npm run watch'
alias npmu='npm run uninstall'
alias npmc='npm install & composer install'

# Yarn
alias y='yarn'
alias yi='yarn init'
alias ya='yarn add'
alias yad='yarn add --dev'
alias yga='yarn global add'
alias yr='yarn run'
alias ys='yarn start'
alias yis='yarn install && yarn start'
alias yrm='yarn remove'
alias yup='yarn upgrade'
alias ycl='yarn clean'
alias ych='yarn check'
alias yt='yarn test'
alias ycc='yarn cache clean'

# Nvm
alias nvmci='nvm install'
alias nvmu='nvm uninstall'
alias nvmc='nvm current'
alias nvmv='nvm version'
alias nvmlr='nvm ls-remote'

# Git
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gca='git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gco='git checkout'
alias gd='git diff'
alias gl='git pull'
alias glg='git log --stat'
alias glog='git log --oneline --decorate --graph'
alias gm='git merge'
alias gp='git push'
alias gst='git status'
alias lg='lazygit'
alias gcl='git clone'

# Git Large Storage
alias gitli='git lfs install'
alias gitlt='git lfs track $1'

# Composer
alias c='composer'
alias cda='composer dump-autoload'
alias ci='composer install'
alias cr='composer require'
alias crm='composer remove'
alias cu='composer update'

# PHP code sniffer
alias codewp='phpcs --config-set default_standard WordPress'
alias codelaravel='phpcs --config-set default_standard Laravel'

alias ibrew='arch -x86_64 /usr/local/bin/brew'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
