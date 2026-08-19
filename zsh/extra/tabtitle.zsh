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
#  emits: a Nerd Font glyph prefixed to the OSC 2 window title, chosen from the
#  command about to run using iTerm2's own command list (see the table below).
#
#  Two things make that render rather than show a Last Resort box:
#
#    1. `window-title-font-family = "Hack Nerd Font"` in .config/ghostty/config.
#       Ghostty only sets `tab.attributedTitle` — the thing that fonts the
#       native tab label — when that key is set. Without it the label uses the
#       system font, and macOS font fallback does *not* reach into installed
#       Nerd Fonts for a Private Use Area codepoint: CTFontCreateForString
#       returns LastResort for U+E795 under .SFNS, measured.
#    2. `no-title` in `shell-integration-features`. Ghostty's own zsh
#       integration writes OSC 2 from a precmd hook that forcibly reorders
#       itself to the end of precmd_functions, so it would overwrite whatever
#       we set. We take the title over instead of racing it.
#
#  What can't be matched: color. The tab label is one NSAttributedString drawn
#  in NSColor.labelColor, so every glyph is monochrome — iTerm2's per-command
#  tints have nowhere to live.
#
#  Two deliberate deviations from iTerm2:
#
#    - An unmapped command keeps the terminal glyph rather than dropping the
#      icon. A tab that sometimes has an icon and sometimes doesn't reads as
#      broken; iTerm2 gets away with it because its icon sits in its own slot
#      and ours would shift the label.
#    - `nvim` shares vim's glyph. Nerd Fonts only added a Neovim glyph at
#      U+E6AE, which is outside this font's charset (it covers E5FA-E634 and
#      E700-E7C5 — checked with `fc-list --format='%{charset}'`).
#
#  Codepoints are Devicons / Font Awesome / Seti / Font Logos, all of which
#  kept their assignments between Nerd Fonts v2 and v3. The one exception is
#  ethereum (U+FCB9), which only exists in v2's Material range — v3 moved that
#  block to U+F0001+, so it is the one glyph a font upgrade would blank.
#==============================================================================

# Command → glyph. The command lists are iTerm2's, transcribed from
# /Applications/iTerm.app/Contents/Resources/graphic_icons.json (its keys are
# named in the comments so the two can be diffed after an iTerm2 update).
# Written as a case rather than an associative array so it costs nothing at
# startup: the patterns compile into the .zwc and are only walked in preexec.
_tabtitle_glyph_for() {
  emulate -L zsh

  case $1 in
    bash|fish|zsh|tcsh)                      _tabtitle_glyph=$'' ;;  # shell
    git|git-remote-ftp|git-remote-ftps|git-remote-http|git-remote-https)
                                             _tabtitle_glyph=$'' ;;  # git
    vim|vi|Vim|nvim)                         _tabtitle_glyph=$'' ;;  # vim, neovim
    nano|pico)                               _tabtitle_glyph=$'' ;;  # nano, code
    emacs|Emacs)                             _tabtitle_glyph=$'' ;;  # emacs
    tail|less|more)                          _tabtitle_glyph=$'' ;;  # read
    grep|egrep|fgrep|search|find|lookup)     _tabtitle_glyph=$'' ;;  # search
    top|htop|iftop)                          _tabtitle_glyph=$'' ;;  # monitor
    ping)                                    _tabtitle_glyph=$'' ;;  # bullhorn
    curl)                                    _tabtitle_glyph=$'' ;;  # curl
    wget|http)                               _tabtitle_glyph=$'' ;;  # http
    docker|docker-compose)                   _tabtitle_glyph=$'' ;;  # docker
    cc|ccache|clang|gcc|gmake|make|xcodebuild)
                                             _tabtitle_glyph=$'' ;;  # compile
    zip|unzip|gzip|gunzip|gzcat|bzip2|bunzip2|tar|gz|winzip|zar)
                                             _tabtitle_glyph=$'' ;;  # zip
    node)                                    _tabtitle_glyph=$'' ;;  # nodejs
    npm|npx)                                 _tabtitle_glyph=$'' ;;  # npm
    yarn|yarnpkg)                            _tabtitle_glyph=$'' ;;  # yarn
    php|composer|composer.phar)              _tabtitle_glyph=$'' ;;  # php
    python|python[0-9.]*|Python|ipython|IPython|apython|pip|easy_install)
                                             _tabtitle_glyph=$'' ;;  # python
    ruby|irb|rake|sidekiq)                   _tabtitle_glyph=$'' ;;  # ruby
    perl)                                    _tabtitle_glyph=$'' ;;  # perl
    java|javac)                              _tabtitle_glyph=$'' ;;  # java
    go)                                      _tabtitle_glyph=$'' ;;  # go
    lein|planck|lumo)                        _tabtitle_glyph=$'' ;;  # clojure
    elixir|elixirc|iex|mix)                  _tabtitle_glyph=$'' ;;  # elixir
    beam|beam.smp|dialyzer|epmd|erl|erlc|escript|run_erl|to_erl)
                                             _tabtitle_glyph=$'' ;;  # erlang
    ethereum|geth|testrpc)                   _tabtitle_glyph=$'ﲹ' ;;  # ethereum
    heroku)                                  _tabtitle_glyph=$'' ;;  # heroku
    postgres|psql)                           _tabtitle_glyph=$'' ;;  # postgres
    mongo|mongod|mongodb|mysql|sqlite3|postmaster|pgbench|pg_dump|pg_dumpall|pg_restore|pg_upgrade|redis-cli|redis-server|redis-sentinel|redis-benchmark|redis-check-aof|redis-check-rdb)
                                             _tabtitle_glyph=$'' ;;  # database
    claude)                                  _tabtitle_glyph=$'' ;;  # claude_code
    *)                                       _tabtitle_glyph=$'' ;;  # (see above)
  esac
}

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
  # Same title text Ghostty's own integration would have written: the working
  # directory at the prompt, the command line while one runs. Only the glyph in
  # front of it is ours.
  _tabtitle_precmd() {
    emulate -L zsh
    printf '\033]2;%s %s\a' $'' "${(%):-%(4~|…/%3~|%~)}"
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
