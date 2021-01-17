#!/usr/bin

# Shourtcuts
alias copyssh="pbcopy < $HOME/.ssh/id_rsa.pub"
alias reloadshell="source $HOME/.zshrc"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias c='clear'
alias o='open .'
alias x='exit'
alias search-history='$(history | cut -c8- | sort -u | pick)'

# Directories
alias dt="cd $HOME/Desktop"
alias dev="cd $HOME/Dev"
alias sites="cd $HOME/Sites"
alias dl="cd $HOME/Downloads"
alias dotfiles="cd $HOME/dotfiles"

alias caliases="code $DOTFILES/aliases.zsh"
alias chammerspoon="code $HOME/.hammerspoon/init.lua"
alias cyabai="code $HOME/.yabairc"
alias czshrc="code $HOME/.zshrc"
alias czshrc="code $HOME/.spacebarrc"
alias cnvims="code $HOME/.config/nvim/init.vim"
alias valetconfig="code /usr/local/etc/nginx/valet/valet.conf"

# Common aliases
alias rdir='rm -rf'
alias rfile='rm'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias wget='wget -c'
alias mkcd=mcd

# Disable correction.
alias ack='nocorrect ack'
alias cd='nocorrect cd'
alias cp='nocorrect cp'
alias ebuild='nocorrect ebuild'
alias gcc='nocorrect gcc'
alias gist='nocorrect gist'
alias grep='nocorrect grep'
alias heroku='nocorrect heroku'
alias ln='nocorrect ln'
alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
alias rm='nocorrect rm'

alias a='fasd -a'        # any
alias s='fasd -si'       # show / search / select
alias d='fasd -d'        # directory
alias f='fasd -f'        # file
alias sd='fasd -sid'     # interactive directory selection
alias sf='fasd -sif'     # interactive file selection
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
alias zz='fasd_cd -d -i' # cd with interactive selection

alias ls='colorls --sd -A'
alias l='colorls --group-directories-first --almost-all'
alias ll='colorls --group-directories-first --almost-all --long'
alias lc='colorls -lA --sd'
alias l='colorls --group-directories-first --almost-all --tree=1'
alias ll='colorls --group-directories-first --almost-all --long'
alias ld='colorls --group-directories-first --almost-all --dirs --tree=1'
alias lf='colorls --group-directories-first --almost-all --files --tree=1'
alias lt1='colorls --group-directories-first --almost-all --tree=1'

# Mac Helpers
alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias deleteiconcache='sudo find /private/var/folders/ -name com.apple.dock.iconcache -exec rm {} \;'
alias killdock='killall Dock'

# computer power options
alias reboot='sudo /sbin/reboot'
alias shutdown='sudo /sbin/shutdown'
alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'
alias poweroff='sudo /sbin/poweroff'

# Google Chrome
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'

# Removes all node_modules folders older than 4 months:
alias cnodeold='find . -name "node_modules" -type d -mtime +120 | xargs rm -rf'

# Removes all node_modules folders:
alias cnodeall='find . -name "node_modules" -type d | xargs rm -rf'

alias getsalts="curl https://api.wordpress.org/secret-key/1.1/salt/"

# Brew Services
alias brewsr mariadb='brew services start mariadb'
alias brewsr dnsmasq='brew services start dnsmasq'
alias brewsr php='brew services start php'

# Tiling window manager
alias yabres='brew services restart yabai && brew services restart skhd && brew services restart spacebar'
alias yabrestart='brew services start yabai && brew services start skhd'
alias yabrestop='brew services stop yabai && brew services stop skhd'
alias yabupdate='brew services stop yabai && brew upgrade yabai && sudo yabai --uninstall-sa && sudo yabai --install-sa && brew services start yabai'

# Valet
alias vstart='valet start'
alias vstop='valet stop'
alias vr='valet start'
alias vls='valet links'
alias vl='valet link'
alias vul='valet unlink'
alias vhttps='valet secure'

alias evalet='code /usr/local/etc/php/7.4/php-fpm.d/valet-fpm.conf'

# SSH
alias sshconfig='cd ~/.ssh; code config'
alias sshkeygen='ssh-keygen -t rsa'
alias copyssh='ssh-copy-id -i ~/.ssh/id_rsa.pub'
alias chmodssh='sudo chmod 700 ~/.ssh && chmod 600 ~/.ssh/*'

# Firebase
alias fblogin='firebase login'
alias fbprojects='firebase projects:list'
alias fblogout='firebase logout'
alias fbini='firebase init'
alias fbdeploy='firebase deploy'

# Enable aliases to be sudo’ed
alias root='sudo -i'
alias su='sudo -i'
alias sudo='sudo '
alias sudomount='sudo mount -uw /'
alias sudo='nocorrect sudo'

alias permission='chmod +x'

# Get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update='brew update; brew upgrade; brew cleanup; brew cask upgrade; npm install npm -g; npm update -g; sudo gem update colorls -n /usr/local/bin; wp cli update; composer global update; zinit update'

# Recursively remove .DS_Store files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# Brew
alias brewl='brew list'
alias brewi='brew install'
alias brewri='brew reinstall'
alias brewr='brew remove'
alias brewcl='brew list --cask'
alias brewd='brew doctor'
alias brewsr='brew services restart'
alias brewsl='brew services list'

# FZF
alias hist="history | fzf"

# Yo Generators
alias newWebApp='yo webapp'

# DOTNET
alias dotnetpublish='dotnet publish -c Release'

# Spicetify
alias sp='spicetify -h'
alias spu='spicetify update'
alias spd='spicetify enable-devtool'
alias spr='spicetify restart'
alias spb='spicetify backup apply'

# WordPress
alias newwp=install_wp
alias wpcore='wp core download'
alias newwpconfig='wp config create'
alias newwpplugin='wp scaffold plugin'
alias wpignore='wp_gitignore'
alias wpdbcheck='wp db check'
alias wprepairdb='wp db repair'
alias wpoptimize='wp db optimize'
alias wpchildtheme='wp scaffold child-theme'
alias wpupdateplugins='wp plugin update --all'
alias wppages="wp post list --post_type='page'"

# ZIM
alias zimu='zimfw update'
alias zimi='zimfw install'
alias zimun='zimfw uninstall'
alias zimup='zimfw upgrade'

# NVM
alias nvmv='nvm --version'
alias nvmlr='nvm ls-remote'
alias nvmcur='nvm current'
alias nvmu='nvm use'
alias nvmyarn='npm install -g yarn'

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
alias npmoutdated='npm outdated'
alias npms='npm install --save'
alias npmsd='npm install --save-dev'
alias npmrw='npm run watch'
alias npmu='npm run uninstall'
alias npmc='npm install & composer install'

# Yarn
alias ys='yarn start'
alias ya='yarn add'
alias yag='yarn global add'
alias yac='yarn install & composer install'
alias yui='yarn upgrade-interactive --latest'

# Git
# Git
alias gst="git status"
alias gb="git branch"
alias gc="git checkout"
alias gl="git log --oneline --decorate --color"
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias diff="git diff"
alias force="git push --force"
alias nuke="git clean -df && git reset --hard"
alias pop="git stash pop"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias wip="commit wip"

# Git Large Storage
alias gitli='git lfs install'
alias gitlt='git lfs track $1'

# Composer
alias ci='composer install'
alias cu='composer update'
alias cgu='composer global update'
alias cda='composer dump-autoload -o'
alias cc='composer clear-cache'

# Laravel Database
alias artm='php artisan migrate'
alias artfs='php artisan migrate:fresh --seed'
alias artrf='php artisan migrate:refresh'

# Laravel Tests
alias artftest='php artisan make:test'
alias artut='php artisan make:test --unit'

# Laravel Makers
alias artmc='php artisan make:controller'
alias artmevent='php artisan make:event'
alias artmmodel='php artisan make:model'
alias artmmigration='php artisan make:migration'
alias artmseed='php artisan make:seed'
alias artmprovider='php artisan make:provider'
alias artrlist='php artisan route:list'

# PHP code sniffer
alias codewp='phpcs --config-set default_standard WordPress'
alias codelaravel='phpcs --config-set default_standard Laravel'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
