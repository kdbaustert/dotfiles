#==============================================================================
#  tabtitle.zsh — put an icon in Ghostty's tab, the way iTerm2 does
#------------------------------------------------------------------------------
#  iTerm2 draws a real image next to each tab label: it maps the tab's current
#  job to a bundled PNG (Resources/graphic_*.tiff, indexed by
#  Resources/graphic_icons.json) and tints it from graphic_colors.json — `zsh`
#  lands on the terminal glyph tinted #C5DB00, which is the green terminal icon
#  in its tabs. Ghostty has no equivalent. Its macOS tabs are the *native*
#  AppKit NSTabBar relocated into the titlebar, and an NSWindowTab label is a
#  string, not an image + string — there is nothing in the config to hang an
#  icon on.
#
#  So the icon has to be a character inside the title, which is what this file
#  emits: a glyph prefixed to the OSC 2 window title, chosen from the command
#  about to run using iTerm2's own command list. The command → codepoint table
#  is generated into tabtitle-icons.zsh beside this file; everything here is the
#  part that decides *which* command we are looking at and when to write.
#
#  Three things make that render rather than show a Last Resort box:
#
#    1. `window-title-font-family` in .config/ghostty/config. Ghostty only sets
#       `tab.attributedTitle` — the thing that fonts the native tab label — when
#       that key is set. Without it the label uses the system font, and macOS
#       font fallback does *not* reach into installed Nerd Fonts for a Private
#       Use Area codepoint: CTFontCreateForString returns LastResort for U+E795
#       under .SFNS, measured.
#    2. `no-title` in `shell-integration-features`. Ghostty's own zsh
#       integration writes OSC 2 from a precmd hook that forcibly reorders
#       itself to the end of precmd_functions, so it would overwrite whatever
#       we set. We take the title over instead of racing it.
#    3. The font that key names is our own build — see fonts/build-tab-icons.py.
#       It carries the icons a second time under plane-16 codepoints with
#       iTerm2's tints baked into a COLR table, which is what makes them
#       colored: the tab label is one NSAttributedString with a single
#       .foregroundColor, so a color font is the only thing that outranks it.
#       Commands iTerm2 has no tint for keep the plain Nerd Font codepoint and
#       stay monochrome, exactly as iTerm2 leaves them.
#
#  Three deliberate deviations from iTerm2:
#
#    - Tints too dark to read on Voltage's background are lifted in lightness
#      until they clear 4.5:1. iTerm2 picked them for a far lighter tab bar;
#      elixir's #440e60 measures 1.36:1 against #0F0D0E. Hue and saturation are
#      untouched, so they still read as the same colors — the build script has
#      the rule and prints every one it moves.
#    - An unmapped command keeps the terminal glyph rather than dropping the
#      icon. A tab that sometimes has an icon and sometimes doesn't reads as
#      broken; iTerm2 gets away with it because its icon sits in its own slot
#      and ours would shift the label.
#    - `nvim` shares vim's glyph but takes iTerm2's neovim green. Nerd Fonts
#      only added a Neovim glyph at U+E6AE, which is outside this font's
#      charset (it covers E5FA-E634 and E700-E7C5 — checked with
#      `fc-list --format='%{charset}'`); the color, unlike the picture, is ours
#      to assign.
#==============================================================================

# The job iTerm2 would be looking at. It reads the foreground process straight
# off the pty; all we have in preexec is the line as typed, so the equivalent
# is the first real word — past any VAR=value assignments and any wrapper that
# execs something else, which is exactly the set of words that would otherwise
# make every `sudo` tab show the same icon.
#
# Sets $_tabtitle_job rather than printing it, for the same reason the glyph
# lookup does: this runs before every command, and a command substitution to
# read it back would fork a subshell each time.
_tabtitle_job_from() {
  emulate -L zsh

  # skip=1 swallows the next word: it belongs to the flag before it, not to the
  # command. Only sudo/doas value-taking short flags are listed, and the scan
  # stops at the first command word anyway, so this never reaches a real
  # command's own arguments — `sudo -u www php ...` reports php, not www.
  local word skip=0
  for word in ${(z)1}; do
    (( skip )) && { skip=0; continue }
    case $word in
      -[CDRTUghpu])                                 skip=1; continue ;;
      *=*|-*)                                       continue ;;
      sudo|doas|command|builtin|exec|nohup|env|time) continue ;;
      *)                                            break ;;
    esac
  done

  # Basename, because $PATH-qualified invocations (./configure, /usr/bin/vim)
  # are the same job to iTerm2 as the bare name.
  _tabtitle_job=${word:t}
}

# Ghostty only. iTerm2 draws its own icon and needs no help, and any other
# terminal would render this as a missing-glyph box.
if [[ -o interactive && $TERM_PROGRAM == ghostty ]]; then
  # The command → codepoint table, generated alongside the font so the two can
  # never disagree about which private-use codepoint carries which tint. Sourced
  # inside the guard so every other terminal skips the file read entirely.
  source "${0:A:h}/tabtitle-icons.zsh"

  # At an idle prompt the foreground job *is* the shell, which is what iTerm2
  # shows there too. Resolved once rather than per-prompt, and through the table
  # rather than as a literal, so a regenerated font cannot leave this behind.
  typeset -g _tabtitle_prompt_glyph
  _tabtitle_glyph_for zsh
  _tabtitle_prompt_glyph=$_tabtitle_glyph
  unset _tabtitle_glyph

  # Same title text Ghostty's own integration would have written: the working
  # directory at the prompt, the command line while one runs. Only the glyph in
  # front of it is ours.
  _tabtitle_precmd() {
    emulate -L zsh
    printf '\033]2;%s %s\a' "$_tabtitle_prompt_glyph" "${(%):-%(4~|…/%3~|%~)}"
  }

  _tabtitle_preexec() {
    emulate -L zsh
    local _tabtitle_job _tabtitle_glyph
    _tabtitle_job_from "$1"
    _tabtitle_glyph_for "$_tabtitle_job"
    printf '\033]2;%s %s\a' "$_tabtitle_glyph" "${1//[[:cntrl:]]}"
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _tabtitle_precmd
  add-zsh-hook preexec _tabtitle_preexec
fi
