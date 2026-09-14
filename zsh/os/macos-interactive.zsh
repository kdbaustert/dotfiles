#!/usr/bin/env zsh
#==============================================================================
#  zsh/os/macos-interactive.zsh — interactive config that exists only on macOS
#------------------------------------------------------------------------------
#  Sourced from .zshrc via $DOTFILES_OS, AFTER zsh/aliases.zsh (so anything here
#  can override a portable alias) and after the tool-integration block (so the
#  command-not-found handler below is the last one defined — see .zshrc).
#
#  What belongs here: aliases and integrations with no counterpart on Linux, or
#  whose two versions share nothing but intent. A setting that is the same knob
#  with a different value stays inline in the shared file so the pair is
#  visible — `pbcopy` is deliberately NOT redefined here for that reason: it is
#  a real macOS binary, and the Linux file provides the shim instead.
#==============================================================================

#------------------------------------------------------------------------------
# command-not-found
#------------------------------------------------------------------------------
# Suggest the formula that provides an unknown command (`brew which-formula`
# under the hood). Shipped in Homebrew core now — the old
# homebrew/command-not-found tap was deprecated.
#
# Source the handler directly rather than `eval "$(brew command-not-found-init)"`
# so we don't spawn brew on every startup; $HOMEBREW_REPOSITORY is exported by
# zsh/os/macos-env.zsh. With pay-respects' --nocnf in .zshrc this is the only
# handler defined — but .zshrc still sources this file last so it wins if that
# flag is ever dropped.
() {
  local h="${HOMEBREW_REPOSITORY:-/opt/homebrew}/Library/Homebrew/command-not-found/handler.sh"
  [[ -r $h ]] && source "$h"
}

#------------------------------------------------------------------------------
# Directories
#------------------------------------------------------------------------------
alias phpdir="cd /opt/homebrew/etc/php"
# The inner single quotes matter: both paths contain a space. $HOME is expanded
# now, at definition time, and the quotes survive into the alias body.
alias vscode="cd '$HOME/Library/Application Support/Code'"
alias icloud="cd '$HOME/Library/Mobile Documents'"

#------------------------------------------------------------------------------
# Power and session
#------------------------------------------------------------------------------
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
# 🔇
alias stfu="osascript -e 'set volume output muted true'"

#------------------------------------------------------------------------------
# OS maintenance
#------------------------------------------------------------------------------
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias clearDNSCache='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias purgemem='sudo purge'
alias testspeed="networkQuality"

# Fix LSD pegging the CPU
# https://discussions.apple.com/message/30186026#message30186026
alias fixlsd="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user ; killall Dock"
alias resetlsd=fixlsd

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# Delete all screenshots from the Desktop. macOS-only because of the filename:
# it is the "Screenshot 2026-09-13 at 10.41.02.png" / "Screen Shot …" pair the
# system writes. Linux screenshot tools each name their own way, so there is no
# faithful equivalent to pair this with.
alias rmshots="find ~/Desktop -maxdepth 1 -type f \( -name 'Screenshot *.png' -o -name 'Screen Shot *.png' \) -print -delete"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

#------------------------------------------------------------------------------
# Homebrew
#------------------------------------------------------------------------------
alias brewf='$(brew --prefix)'
alias ibrew='arch -x86_64 /usr/local/bin/brew'

# Everything the machine can update in one go. The tail (npm/composer/zinit) is
# identical on Linux; only the package-manager head differs, which is why the
# whole alias is duplicated per platform rather than split into two halves —
# a `$PKG_UPDATE` variable spliced into a shared string would be harder to read
# than the two plain lines it saves.
alias update='brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; composer global update; zinit update'
