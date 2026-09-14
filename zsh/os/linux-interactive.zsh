#!/usr/bin/env zsh
#==============================================================================
#  zsh/os/linux-interactive.zsh — interactive config only for Arch/Manjaro
#------------------------------------------------------------------------------
#  The counterpart to macos-interactive.zsh, sourced from .zshrc via
#  $DOTFILES_OS, after zsh/aliases.zsh and after the tool-integration block.
#
#  Two jobs: provide the Linux half of the commands whose macOS half is an Apple
#  tool, and shim the handful of macOS command NAMES that the portable files
#  deliberately keep using (pbcopy, open). The shims are what let aliases.zsh
#  carry `shrug`, `genpass`, `pkey`, `pubkey` and `o` with no branch at all.
#==============================================================================

#------------------------------------------------------------------------------
# command-not-found
#------------------------------------------------------------------------------
# Arch's equivalent of Homebrew's handler: pkgfile owns a files database and
# suggests the package providing an unknown command. The database is NOT built
# at install time — `pkgfile -u` has to run once (install-linux.sh does it, and
# the pkgfile-update.timer keeps it current), and until it has, the handler
# simply finds nothing rather than erroring.
#
# Sourced rather than reimplemented: the script defines
# command_not_found_handler itself, exactly as the Homebrew one does, so the
# "last definition wins" ordering .zshrc relies on works the same way here.
[[ -r /usr/share/doc/pkgfile/command-not-found.zsh ]] \
  && source /usr/share/doc/pkgfile/command-not-found.zsh

#------------------------------------------------------------------------------
# man pages
#------------------------------------------------------------------------------
# The companion to MANPAGER in .zshrc, and not optional here. Arch ships groff,
# which honours MANROFFOPT; `-c` disables its own pager-oriented output so the
# overstrike sequences `col -bx` expects are the ones it actually emits. Without
# it the page reaches bat with escape codes intact and renders as garbage.
# macOS needs no twin — mandoc ignores the variable entirely (verified: output
# identical with and without), which is why this is one-sided rather than a pair.
export MANROFFOPT="-c"

#------------------------------------------------------------------------------
# macOS command-name shims
#------------------------------------------------------------------------------
# Functions, not aliases, for the clipboard pair: they read stdin and take no
# arguments, and a function resolves at call time, so aliases.zsh being sourced
# BEFORE this file is irrelevant. (zsh would re-expand an alias body too, but
# only for the first word — `pbcopy < file` in `pkey` is fine either way, while
# a pipeline is clearer as a function.)
#
# Wayland first, X11 second, checked per call rather than once at startup: a
# session can be either, and on a machine that runs both this stays correct
# without a reload. Both are one `[[ -n ]]` test, so the cost is nil.
pbcopy() {
  if [[ -n $WAYLAND_DISPLAY ]]; then
    wl-copy
  else
    xclip -selection clipboard
  fi
}

pbpaste() {
  if [[ -n $WAYLAND_DISPLAY ]]; then
    wl-paste --no-newline
  else
    xclip -selection clipboard -o
  fi
}

# `open` backs the `o` alias in aliases.zsh, and is worth having under its macOS
# name for muscle memory on any path (`open report.pdf`). Safe to claim: Arch
# ships no /usr/bin/open, so nothing is being shadowed.
alias open='xdg-open'

#------------------------------------------------------------------------------
# Power and session
#------------------------------------------------------------------------------
# systemd owns all of these, and none of them needs sudo — logind authorises the
# active session through polkit, which is the real difference from the macOS
# side where each one is a sudo'd /sbin binary.
alias lock='loginctl lock-session'
# `reboot` and `poweroff` are real commands here that already do the right
# thing, so they are deliberately NOT aliased — unlike macOS, where /sbin/reboot
# needs sudo and there is no poweroff at all. Aliasing them to systemctl verbs
# would add a layer that changes nothing.
alias stfu='wpctl set-mute @DEFAULT_AUDIO_SINK@ 1'

#------------------------------------------------------------------------------
# OS maintenance
#------------------------------------------------------------------------------
# systemd-resolved holds the DNS cache. Both names kept so muscle memory from
# the macOS side lands somewhere.
alias reloaddns='resolvectl flush-caches'
alias clearDNSCache='resolvectl flush-caches'
# `purge` has no equivalent worth aliasing: dropping caches needs a root shell
# redirect (`echo 3 > /proc/sys/vm/drop_caches`) and the kernel reclaims that
# memory under pressure anyway, so the macOS habit does not transfer.

# Chrome's renderer processes are named `--type=renderer` here too, but without
# the "Chrome Helper" wrapper macOS uses, so the pattern differs.
alias chromekill="pkill -f '[c]hrome.*--type=renderer'"

#------------------------------------------------------------------------------
# Packages
#------------------------------------------------------------------------------
# See the note on the macOS `update`: same tail, different head. `paru` covers
# repo and AUR packages in one pass; swap for `yay` or plain `pacman -Syu` if
# the AUR helper ever changes.
alias update='paru -Syu; npm install npm -g; npm update -g; composer global update; zinit update'
