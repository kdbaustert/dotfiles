#!/usr/bin/env zsh
#==============================================================================
#  zsh/os/linux-env.zsh — login environment that exists only on Arch/Manjaro
#------------------------------------------------------------------------------
#  The counterpart to macos-env.zsh, and deliberately almost empty. That is the
#  useful fact this file records rather than a gap in it: pacman installs into
#  /usr, so there is no prefix to export, no completions directory to add (zsh
#  has /usr/share/zsh/site-functions on the default fpath), and no man path to
#  correct. Homebrew needs nine lines on macOS to undo what a system package
#  manager gets right by default.
#
#  Keep it that way. A setting that exists on BOTH platforms with a different
#  value belongs inline in .zprofile as an if/else — see PNPM_HOME there — so
#  the two halves stay visible to each other. Only genuinely one-sided things
#  land in this file.
#==============================================================================

# Nothing yet.
#
# The things that would plausibly go here are already handled elsewhere:
#
#   - ~/.local/bin and ~/.config/composer/vendor/bin are in the shared path
#     array in .zprofile; they are the same on both platforms.
#   - PNPM_HOME is the inline pair in .zprofile.
#   - The Nix daemon hook is at the same /nix/var/nix/profiles/default path on
#     Linux as on macOS, so .zprofile's existing source line covers both.
#   - XDG_RUNTIME_DIR is set by systemd's pam_systemd, not by a shell file.
#
# Two that will matter if the machine grows them, noted so the next session
# does not have to re-derive where they go:
#
#   - A JVM or SDK prefix (/usr/lib/jvm/...) is one-sided and belongs here.
#   - GTK/Qt theme variables for the Voltage palette would be one-sided too,
#     but they are display-server environment rather than shell environment and
#     belong in the session config, not in a login shell file.
