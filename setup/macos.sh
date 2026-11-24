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
defaults write NSGlobalDomain AppleAntiAliasingThreshold -int 4
defaults write NSGlobalDomain AppleLanguagesSchemaVersion -int 5400
defaults write NSGlobalDomain AppleLocale -string en_US
defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
defaults write NSGlobalDomain KB_DoubleQuoteOption -string '“abc”'
defaults write NSGlobalDomain KB_SingleQuoteOption -string '‘abc’'
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool true
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSCloseAlwaysConfirmsWindows -bool false
defaults write NSGlobalDomain NSGlassBuddyTintAmount -float 1
defaults write NSGlobalDomain NSGlassEverEditedInBuddy -bool true
defaults write NSGlobalDomain NSGlassTintAmount -float 1
defaults write NSGlobalDomain NSSpellCheckerContainerTransitionComplete -bool true
defaults write NSGlobalDomain NSSpellCheckerDictionaryContainerTransitionComplete -bool true
defaults write NSGlobalDomain PKFPANInitialEligibilityCheckPerformedKey -bool true
defaults write NSGlobalDomain com.apple.sound.beep.flash -int 0
defaults write NSGlobalDomain com.apple.springing.delay -float 0.5
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true
defaults write NSGlobalDomain shouldShowRSVPDataDetectors -bool false

###############################################################################
# Screen                                                                      #
###############################################################################

# Save screenshots to ~/Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"
defaults write com.apple.screencapture target-screenrecording -string file
defaults write com.apple.screencapture target-screenshot -string file

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
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder CopyProgressWindowLocation -string '{869, 142}'
defaults write com.apple.finder DataSeparatedDisplayNameCache -string ''
defaults write com.apple.finder DownloadsFolderListViewSettingsVersion -int 1
defaults write com.apple.finder EmptyTrashProgressWindowLocation -string '{828, 388}'
defaults write com.apple.finder FK_AppCentricShowSidebar -bool true
defaults write com.apple.finder FK_SidebarWidth2 -float 159
defaults write com.apple.finder FXArrangeGroupViewBy -string Name
defaults write com.apple.finder FXDesktopTouchBarUpgradedToTenTwelveOne -int 1
defaults write com.apple.finder FXDetachedDesktopProviderID -string ''
defaults write com.apple.finder FXDetachedDocumentsProviderID -string ''
defaults write com.apple.finder FXICloudDriveDesktop -bool false
defaults write com.apple.finder FXICloudDriveDocuments -bool false
defaults write com.apple.finder FXICloudDriveEnabled -bool true
defaults write com.apple.finder FXICloudLoggedIn -bool true
defaults write com.apple.finder FXInfoWindowWidth -float 400
defaults write com.apple.finder FXLastSearchScope -string SCcf
defaults write com.apple.finder FXPreferencesWindow.Location -string '{{10, 503}, {377, 426}}'
defaults write com.apple.finder FXPreferredGroupBy -string Name
defaults write com.apple.finder FXPreferredSearchViewStyleVersion -string '%00%00%00%01'
defaults write com.apple.finder FXQuickActionsConfigUpgradeLevel -int 3
defaults write com.apple.finder FXSidebarUpgradedToSixteen -bool true
defaults write com.apple.finder FXToolbarUpgradedToTenEight -int 1
defaults write com.apple.finder FXToolbarUpgradedToTenNine -int 2
defaults write com.apple.finder FXToolbarUpgradedToTenSeven -int 1
defaults write com.apple.finder FinderSpawnTab -bool false
defaults write com.apple.finder GoToField -string '~/.ssh/'
defaults write com.apple.finder NSNavPanelExpandedSizeForOpenMode -string '{880, 448}'
defaults write com.apple.finder PreviewPaneGalleryWidth -float 240
defaults write com.apple.finder PreviewPaneWidth -float 240
defaults write com.apple.finder RecentsArrangeGroupViewBy -string 'Date Last Opened'
defaults write com.apple.finder SearchRecentsSavedViewStyleVersion -string '%00%00%00%01'
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
defaults write com.apple.finder ShowSidebar -bool true
defaults write com.apple.finder SidebarDevicesSectionDisclosedState -bool true
defaults write com.apple.finder SidebarPlacesSectionDisclosedState -bool true
defaults write com.apple.finder SidebarTagsSctionDisclosedState -bool false
defaults write com.apple.finder SidebarWidth2 -float 211
defaults write com.apple.finder TagsCloudSerialNumber -int 1

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
defaults write com.apple.dock tilesize -int 30

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
defaults write com.apple.dock loc -string en_US:US
defaults write com.apple.dock no-bouncing -bool true
defaults write com.apple.dock region -string US
defaults write com.apple.dock trash-full -bool false
defaults write com.apple.dock version -int 1
defaults write com.apple.dock wvous-br-corner -int 14

###############################################################################
# Menu bar                                                                    #
###############################################################################

# Menu bar clock: show the day of week but hide the date
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0
defaults write com.apple.menuextra.clock ShowAMPM -bool true

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
defaults write com.apple.AppleMultitouchMouse MouseButtonDivision -int 55
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string OneButton
defaults write com.apple.AppleMultitouchMouse MouseHorizontalScroll -bool true
defaults write com.apple.AppleMultitouchMouse MouseMomentumScroll -bool true
defaults write com.apple.AppleMultitouchMouse MouseOneFingerDoubleTapGesture -int 0
defaults write com.apple.AppleMultitouchMouse MouseTwoFingerDoubleTapGesture -int 3
defaults write com.apple.AppleMultitouchMouse MouseTwoFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchMouse MouseVerticalScroll -bool true
defaults write com.apple.AppleMultitouchMouse UserPreferences -bool true
defaults write com.apple.AppleMultitouchMouse version -int 1
defaults write com.apple.AppleMultitouchTrackpad ActuateDetents -int 1
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 0
defaults write com.apple.AppleMultitouchTrackpad DragLock -int 0
defaults write com.apple.AppleMultitouchTrackpad Dragging -int 0
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool false
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadHandResting -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadHorizScroll -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadMomentumScroll -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadScroll -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
defaults write com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad -int 0
defaults write com.apple.AppleMultitouchTrackpad UserPreferences -bool true
defaults write com.apple.AppleMultitouchTrackpad version -int 12
defaults write com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID -string com.apple.keylayout.US
defaults write com.apple.Siri ConfirmSiriInvokedViaEitherCmdTwice -bool false
defaults write com.apple.Siri GMSignedUp -bool true
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool true
defaults write com.apple.Spotlight FTEResetForSuperSpotlight -bool true
defaults write com.apple.Spotlight ModelName -string Canned
defaults write com.apple.Spotlight PasteboardHistoryNeedsWipe -bool false
defaults write com.apple.Spotlight PasteboardHistoryVersion -int 4
defaults write com.apple.Spotlight PreferencesVersion -int 2
defaults write com.apple.Spotlight SSActionKeyboardAliasStoreVersion -int 1
defaults write com.apple.Spotlight __NSEnableTSMDocumentWindowLevel -bool true
defaults write com.apple.Spotlight showedFTE -bool true
defaults write com.apple.Spotlight showedLearnMore -bool true
defaults write com.apple.TextInputMenu visible -bool false
defaults write com.apple.WindowManager AppWindowGroupingBehavior -int 1
defaults write com.apple.WindowManager AutoHide -bool true
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager HasDisplayedShowDesktopEducation -bool true
defaults write com.apple.WindowManager HideDesktop -bool true
defaults write com.apple.WindowManager StageManagerHideWidgets -bool false
defaults write com.apple.WindowManager StandardHideWidgets -bool false
defaults write com.apple.controlcenter HasAttemptedMenuBarWorkflowMigration -bool true
defaults write com.apple.controlcenter 'NSStatusItem Preferred Position BentoBox-0' -float 162
defaults write com.apple.controlcenter 'NSStatusItem Preferred Position WiFi' -float 204
defaults write com.apple.controlcenter 'NSStatusItem VisibleCC BentoBox-0' -bool true
defaults write com.apple.controlcenter 'NSStatusItem VisibleCC Clock' -bool true
defaults write com.apple.controlcenter 'NSStatusItem VisibleCC WiFi' -bool true
defaults write com.apple.controlcenter RemoteLiveActivitiesEnabled -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonDivision -int 55
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string OneButton
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseHorizontalScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseMomentumScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseOneFingerDoubleTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerDoubleTapGesture -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseVerticalScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse UserPreferences -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFiveFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadHandResting -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadHorizScroll -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadMomentumScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadPinch -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRotate -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadScroll -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad USBMouseStopsTrackpad -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad UserPreferences -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad version -int 5
defaults write com.apple.driver.AppleHIDMouse Button1 -int 1
defaults write com.apple.driver.AppleHIDMouse Button2 -int 1
defaults write com.apple.driver.AppleHIDMouse Button3 -int 0
defaults write com.apple.driver.AppleHIDMouse Button4 -int 0
defaults write com.apple.driver.AppleHIDMouse Button4Click -int 0
defaults write com.apple.driver.AppleHIDMouse Button4Force -int 0
defaults write com.apple.driver.AppleHIDMouse ButtonDominance -int 1
defaults write com.apple.driver.AppleHIDMouse ScrollH -int 1
defaults write com.apple.driver.AppleHIDMouse ScrollS -int 4
defaults write com.apple.driver.AppleHIDMouse ScrollSSize -int 30
defaults write com.apple.driver.AppleHIDMouse ScrollV -int 1
defaults write com.apple.keyboard.preferences IsMixmojiSuggestionsEnabled -bool false
defaults write com.apple.loginwindow MiniBuddyLaunch -bool false
defaults write com.apple.loginwindow 'NSWindow Frame LowMemoryPanel' -string '0 0 392 458 0 0 2056 1290 '
defaults write com.apple.loginwindow 'NSWindow Frame ProcessPanel' -string '215 217 370 310 0 0 2056 1290 '
defaults write com.apple.loginwindow TALLogoutReason -string 'Shut Down'
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
defaults write com.apple.loginwindow oneTimeSSMigrationComplete -bool true
defaults write com.apple.screensaver tokenRemovalAction -int 0
defaults write com.apple.systemuiserver __NSEnableTSMDocumentWindowLevel -bool true
defaults write com.apple.universalaccess closeViewHotkeysEnabled -bool false
defaults write com.apple.universalaccess closeViewZoomDisplayID -int 0
defaults write com.apple.universalaccess closeViewZoomFactor -float 1
defaults write com.apple.universalaccess hoverColorEnabled -bool false
defaults write com.apple.universalaccess hoverTextEnabled -bool false
defaults write com.apple.universalaccess hoverTypingEnabled -bool false
defaults write com.apple.universalaccess keyboardAccessFocusRingTimeout -float 15
defaults write com.apple.universalaccess liveSpeechEnabled -bool false
defaults write com.apple.universalaccess login -bool false
defaults write com.apple.universalaccess mouseDriver -bool false
defaults write com.apple.universalaccess sessionChange -bool false
defaults write com.apple.universalaccess slowKey -bool false
defaults write com.apple.universalaccess slowKeyDelay -int 250
defaults write com.apple.universalaccess stickyKey -bool false
defaults write com.apple.universalaccess switchAutoScanElementInterval -float 0.5
defaults write com.apple.universalaccess switchAutoScanPanelInterval -float 0.5
defaults write com.apple.universalaccess switchCoalescePressesDuration -float 0
defaults write com.apple.universalaccess switchFirstElementDelay -float 0
defaults write com.apple.universalaccess switchHideUITimeout -float 15
defaults write com.apple.universalaccess switchHoldBeforeRepeatDuration -float 3
defaults write com.apple.universalaccess switchMinimumPressDuration -float 0
defaults write com.apple.universalaccess switchSweepingCursorSpeed -float 5
defaults write com.apple.universalaccess useStickyKeysShortcutKeys -bool false

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
