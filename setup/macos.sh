#!/usr/bin/env sh

# ~/.macos — macOS system configuration
#
# This file reflects the macOS defaults that are ACTUALLY applied on this Mac.
# It is a curated subset of setup/macos_bk.sh: settings from the backup that are
# not currently in effect on this machine have been left out, and live values
# (e.g. the Dock icon size) are used where they differ from the backup.
#
#   sh setup/macos.sh
#
# Inspired by https://mths.be/macos

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "Kenny’s MacBook Pro"
sudo scutil --set LocalHostName "Kennys-MacBook-Pro"

# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

###############################################################################
# Keyboard & input                                                            #
###############################################################################

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

###############################################################################
# Screen                                                                      #
###############################################################################

# Save screenshots to ~/Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

###############################################################################
# Finder                                                                      #
###############################################################################

# Finder: open new windows in the Home folder
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show the ~/Library folder
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library 2>/dev/null

###############################################################################
# Dock & Mission Control                                                       #
###############################################################################

# Set the icon size of Dock items to 33 pixels
defaults write com.apple.dock tilesize -int 33

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

###############################################################################
# Network                                                                     #
###############################################################################

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

###############################################################################
# Terminal                                                                    #
###############################################################################

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

###############################################################################
# Time Machine                                                                #
###############################################################################

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "cfprefsd" \
  "Dock" \
  "Finder" \
  "SystemUIServer" \
  "Terminal"; do
  killall "${app}" &>/dev/null
done

echo "Done. Note that some of these changes require a logout/restart to take effect."
