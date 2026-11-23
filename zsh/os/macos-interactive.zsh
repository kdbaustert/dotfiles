#!/usr/bin/env zsh
#==============================================================================
#  zsh/os/macos-interactive.zsh: interactive config that exists only on macOS
#------------------------------------------------------------------------------
#  Sourced from .zshrc AFTER zsh/aliases.zsh (so anything here can override a
#  portable alias) and after the tool-integration block (so the
#  command-not-found handler below is the last one defined; see .zshrc).
#
#  What belongs here: aliases and integrations that call Apple tools, Homebrew
#  or paths under ~/Library. Aliases that only need ordinary CLI tools stay in
#  zsh/aliases.zsh.
#==============================================================================

#------------------------------------------------------------------------------
# command-not-found
#------------------------------------------------------------------------------
# Suggest the formula that provides an unknown command (`brew which-formula`
# under the hood). It ships in Homebrew core, so no tap is needed.
#
# Source the handler directly rather than `eval "$(brew command-not-found-init)"`
# so we don't spawn brew on every startup; $HOMEBREW_REPOSITORY is exported by
# zsh/os/macos-env.zsh. With pay-respects' --nocnf in .zshrc this is the only
# handler defined, but .zshrc sources this file last so it wins if that flag
# is ever dropped.
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
# CGSession isn't used: the "Menu Extras" bundle that carried it doesn't exist
# on macOS 26, so that path fails outright. pmset needs no Accessibility grant
# (the osascript Ctrl-Cmd-Q route fails silently without one) and locks straight
# away here, since `sysadminctl -screenLock status` reports an immediate delay.
alias lock='pmset displaysleepnow'
# macOS ships no /sbin/poweroff (that's a Linux/systemd name), only halt,
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

# Delete all screenshots from the Desktop. Matches the
# "Screenshot 2026-09-13 at 10.41.02.png" / "Screen Shot ..." names macOS writes.
alias rmshots="find ~/Desktop -maxdepth 1 -type f \( -name 'Screenshot *.png' -o -name 'Screen Shot *.png' \) -print -delete"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

#------------------------------------------------------------------------------
# Homebrew
#------------------------------------------------------------------------------
alias brewf='$(brew --prefix)'
alias ibrew='arch -x86_64 /usr/local/bin/brew'

#------------------------------------------------------------------------------
# update: everything the machine can update in one go
#------------------------------------------------------------------------------
# A function, not the old one-line alias, so each step can be skipped when its
# tool is missing and a failure is named at the end instead of scrolling past
# in a `;` chain. Every step still runs when an earlier one fails, because
# they're independent: a broken brew bottle shouldn't stop the zinit update.
#
# `brew update` stays even though `brew upgrade` auto-updates: auto-update only
# fires once HOMEBREW_AUTO_UPDATE_SECS (24h by default) has passed, so a second
# `update` the same day would upgrade against a stale index without it.
#
# npm runs twice, once per node, because both hold globals that matter: the
# Homebrew node has `neovim` (nvim's node provider) and nvm's default has
# @continuedev/cli. Which one a bare `npm` reaches depends on whether zsh-nvm's
# turbo-loaded shim exists yet, so neither step trusts it:
#   - Homebrew: its bin dir goes first on PATH, because npm is a
#     `#!/usr/bin/env node` script and with nvm active `env` would hand it nvm's
#     node, whose global prefix is nvm's. npm itself is left to brew, which
#     ships it with node and puts it back on every `brew upgrade node` anyway.
#   - nvm: nvm.sh is sourced in a subshell, so `nvm use` can't change the
#     calling shell's node, and `command npm` skips the zsh-nvm shim function.
#
# composer only runs when its global composer.json exists. setup/composer.sh is
# opt-in, and before it has run `composer global update` just prints an error.
# The phpcs step after it puts Neutron back in installed_paths: phpcs keeps
# that setting in CodeSniffer.conf inside its own vendor folder, so an update
# that brings a new phpcs wipes it and `phpcs --standard=NeutronStandard` stops
# resolving. It's the same command setup/composer.sh runs after its install,
# and it runs on every update because nothing cheap says whether phpcs changed.
# The set replaces the whole installed_paths value, so a second standard has to
# be added here and in setup/composer.sh together.
#
# Mason's LSP servers aren't here: mason has no headless "update everything"
# command without mason-tool-installer, which .config/nvim doesn't use. Press
# U in :Mason. `Lazy! sync` rewrites the tracked .config/nvim/lazy-lock.json,
# which is expected; commit it when the new plugin versions work.
#
# The unalias is for a shell that still has the old `update` alias and
# re-sources .zshrc: the alias would keep winning over this function.
unalias update 2>/dev/null
function update {
  local -a failed
  local brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
  local composer_home neutron

  if (( $+commands[brew] )); then
    _update_step 'brew update' brew update
    _update_step 'brew upgrade' brew upgrade
    _update_step 'brew autoremove' brew autoremove
    _update_step 'brew cleanup' brew cleanup
  fi

  (( $+commands[mas] )) && _update_step 'mas upgrade' mas upgrade

  [[ -x $brew_prefix/bin/npm ]] \
    && _update_step 'npm globals (Homebrew node)' \
      env PATH="$brew_prefix/bin:$PATH" "$brew_prefix/bin/npm" update -g

  [[ -s ${NVM_DIR:-$HOME/.nvm}/nvm.sh ]] \
    && _update_step 'npm globals (nvm default node)' _update_nvm_globals

  (( $+commands[pnpm] )) && _update_step 'pnpm globals' pnpm update -g

  if (( $+commands[composer] )); then
    composer_home="$(composer global config home 2>/dev/null)"
    neutron=$composer_home/vendor/automattic/phpcs-neutron-standard

    if [[ -n $composer_home && -f $composer_home/composer.json ]]; then
      _update_step 'composer globals' composer global update

      [[ -d $neutron ]] && _update_step 'phpcs Neutron standard' \
        "$composer_home/vendor/bin/phpcs" --config-set installed_paths "$neutron"
    fi
  fi

  (( $+commands[gh] )) && _update_step 'gh extensions' gh extension upgrade --all

  # zinit update only pulls plugins; self-update is what updates zinit itself.
  if (( $+functions[zinit] )); then
    _update_step 'zinit self-update' zinit self-update
    _update_step 'zinit plugins' zinit update --all
  fi

  (( $+commands[nvim] )) && _update_step 'neovim plugins' nvim --headless '+Lazy! sync' +qa

  if (( ${#failed} )); then
    print -P "%F{red}==>%f Failed: ${(j:, :)failed}"
    return 1
  fi

  print -P '%F{green}==>%f Everything updated.'
}

# Runs one step of `update` under a header. A failing step appends its label
# to update's local $failed, which is visible here because zsh scopes locals
# dynamically.
#
# @param $1 label shown in the header and in the failure summary
# @param $@ the command to run
function _update_step {
  local label=$1
  shift

  print -P "%F{blue}==>%f %B${label}%b"
  "$@" || failed+=("$label")
}

# Updates npm and the global packages of nvm's default node, in a subshell so
# the calling shell's PATH and active node are left alone.
function _update_nvm_globals {
  (
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    source "$NVM_DIR/nvm.sh" --no-use \
      && nvm use --silent default \
      && command npm install -g npm \
      && command npm update -g
  )
}
