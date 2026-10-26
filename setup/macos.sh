#!/usr/bin/env bash
#
# macOS system configuration: the defaults that are applied on this Mac,
# rather than an aspirational list. bash, not sh, to match the rest of
# setup/ and because `&>` below is not POSIX.
#
# Changes system settings; review before running. Run it through the
# installer rather than calling it directly:
#
#   ./install.sh macos
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

# Set computer name (as done via System Preferences → Sharing). Asked for
# rather than written in, so the script can run on any Mac without renaming
# it after the one it was written on.
#
# local_host_name <name>: the Bonjour form of a computer name. LocalHostName
# allows letters, digits and hyphens, at most 63 of them. Apostrophes are
# dropped rather than turned into hyphens, so "Ada’s Mac" becomes Adas-Mac,
# the same as System Settings does.
local_host_name() {
  local name="$1"

  name="${name//\'/}"
  name="${name//’/}"
  name="$(printf '%s' "$name" | LC_ALL=C tr -cs 'A-Za-z0-9' '-')"
  name="${name#-}"
  name="${name:0:63}"
  name="${name%-}"
  printf '%s\n' "$name"
}

# set_computer_name: ask for the name and set ComputerName plus the
# LocalHostName derived from it. Enter sets nothing: re-deriving from the
# current name would overwrite a LocalHostName chosen by hand, such as a short
# "my-mbp". Skipped under install.sh -y (ASSUME_YES=true), which promises
# no questions, and when stdin is not a terminal, where read would get EOF and
# nobody is around to answer anyway.
set_computer_name() {
  local current name bonjour

  current="$(scutil --get ComputerName 2>/dev/null)"
  if [ "${ASSUME_YES:-false}" = true ] || [ ! -t 0 ]; then
    echo "Not asking for a computer name; left as \"$current\"."
    return 0
  fi

  read -r -p "Computer name (Enter keeps \"$current\"): " name || return 0
  if [ -z "$name" ]; then
    echo "Computer name left as \"$current\"."
    return 0
  fi

  bonjour="$(local_host_name "$name")"
  sudo scutil --set ComputerName "$name"
  if [ -n "$bonjour" ]; then
    sudo scutil --set LocalHostName "$bonjour"
  else
    echo "\"$name\" has no letters or digits for a LocalHostName; left that unchanged."
  fi
}

set_computer_name

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

#Disable the sound effects on boot
sudo nvram StartupMute=%01

###############################################################################
# Appearance                                                                  #
###############################################################################

# Use the Dark interface style
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

###############################################################################
# Keyboard & input                                                            #
###############################################################################

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a very fast keyboard repeat rate
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

# Use icon view in all Finder windows by default
# Four-letter codes: `icnv` icon, `Nlsv` list, `clmv` column, `glyv` gallery
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"

# Default icon-view options for new folders (match the live configuration)
finder_plist="${HOME}/Library/Preferences/com.apple.finder.plist"
for view in StandardViewSettings DesktopViewSettings; do
  /usr/libexec/PlistBuddy -c "Set :${view}:IconViewSettings:arrangeBy name" "${finder_plist}" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :${view}:IconViewSettings:iconSize 64" "${finder_plist}" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :${view}:IconViewSettings:gridSpacing 54" "${finder_plist}" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :${view}:IconViewSettings:textSize 12" "${finder_plist}" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :${view}:IconViewSettings:labelOnBottom true" "${finder_plist}" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :${view}:IconViewSettings:showItemInfo false" "${finder_plist}" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :${view}:IconViewSettings:showIconPreview true" "${finder_plist}" 2>/dev/null
done

# List view: sort by name and use relative dates (Today/Yesterday)
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:ListViewSettings:sortColumn name" "${finder_plist}" 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:ListViewSettings:useRelativeDates 1" "${finder_plist}" 2>/dev/null

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
# Menu bar                                                                    #
###############################################################################

# Menu bar clock: show the day of week but hide the date
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0

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
