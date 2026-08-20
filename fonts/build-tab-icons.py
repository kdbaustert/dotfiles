#!/usr/bin/env python3
# =============================================================================
#  build-tab-icons.py — bake iTerm2's tab-icon tints into a color font
# -----------------------------------------------------------------------------
#  Ghostty draws a native AppKit tab label, and it builds that label as one
#  NSAttributedString with a single foreground color for the whole string
#  (macos/Sources/Features/Terminal/Window Styles/TerminalWindow.swift, the
#  `attributedTitle` property — `.foregroundColor` is hardcoded to labelColor /
#  secondaryLabelColor, with no attribute runs and no config key). So nothing
#  the shell emits can tint a glyph: an escape sequence carries characters, and
#  every character in the label gets the same color.
#
#  The one thing that outranks `.foregroundColor` is a font that carries its own
#  colors. Measured on this machine: a COLR/CPAL glyph drawn through
#  NSAttributedString with `.foregroundColor = .black` comes out in its palette
#  color, exactly — a #C5DB00 glyph and a plain #C5DB00 NSColor fill sample
#  identically (both as #D2DE56, which is the offscreen context's display
#  profile shifting them equally, not the font being approximate).
#
#  So this script takes Hack Nerd Font, adds a COLR/CPAL table covering only the
#  icon glyphs, and renames the family. Latin text has no COLR entry, so the
#  label itself still renders in labelColor and still dims on inactive tabs —
#  only the icon is colored.
#
#  Two artifacts come out, both committed, because a fresh machine has neither
#  fontTools nor (see below) a source Nerd Font to rebuild from:
#
#    fonts/HackNerdFontColor-Regular.ttf   the font, copied into ~/Library/Fonts
#    zsh/extra/tabtitle-icons.zsh          the command -> codepoint lookup
#
#  Regenerate with:  pip install fonttools && python3 fonts/build-tab-icons.py
#  then re-run install.sh — the font is *copied* into ~/Library/Fonts, not
#  linked, because CoreText does not register symlinked fonts (measured: a real
#  copy resolves within ~3s, a symlink stayed invisible through 24s of polling,
#  even though fontconfig listed it the whole time).
#
#  Colors are iTerm2's own, transcribed from
#  /Applications/iTerm.app/Contents/Resources/graphic_colors.json, and the icon
#  glyphs match the table zsh/extra/tabtitle.zsh already took from
#  graphic_icons.json. Keys are named per entry below so the two can be diffed
#  after an iTerm2 update. (That file ships with a trailing comma in its "code"
#  array and does not parse as JSON, which is why this is transcribed rather
#  than read at build time.)
#
#  COLORS stays verbatim for that reason — the one deviation from iTerm2's
#  palette is applied here at build time instead, by `legible()`: several of its
#  tints were picked for a much lighter tab bar and are unreadable on Voltage,
#  so anything under MIN_CONTRAST is lifted in lightness. The build prints every
#  color it moved, and the generated zsh records the original beside the new one.
# =============================================================================

import colorsys
import sys
from copy import deepcopy
from pathlib import Path

from fontTools.colorLib.builder import buildCOLR, buildCPAL
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._c_m_a_p import CmapSubtable

REPO = Path(__file__).resolve().parent.parent
FONT_OUT = REPO / "fonts" / "HackNerdFontColor-Regular.ttf"
ZSH_OUT = REPO / "zsh" / "extra" / "tabtitle-icons.zsh"
FAMILY = "Hack Nerd Font Color"

# Nerd Fonts v2 naming first — that is what is actually installed here; the v3
# cask is declared in the Brewfile but deliberately not installed (see the
# comment there). v3's name is listed too so a rebuilt machine still works.
SOURCE_CANDIDATES = [
    Path.home() / "Library/Fonts/Hack Regular Nerd Font Complete.ttf",
    Path.home() / "Library/Fonts/HackNerdFont-Regular.ttf",
]

# iTerm2's graphic_colors.json, verbatim. Keys are a mix of command names and
# icon names; iTerm2 resolves the command first and falls back to the icon, so
# `zsh` is #C5DB00 while a bare `tcsh` takes the generic `shell` blue.
COLORS = {
    "atom": "#7CB342",      "bash": "#FFF",         "claude_code": "#CC7C5E",
    "curl": "#9CCC65",      "docker": "#0EB7ED",    "docker-compose": "#0EB7ED",
    "elixir": "#440e60",    "emacs": "#7e5cb7",     "erlang": "#7f1831",
    "ethereum": "#8A93B1",  "fish": "#D8494F",      "find": "#9CCC65",
    "geth": "#B2FF59",      "git": "#fc6d26",       "gulp": "#CF4647",
    "heroku": "#6762a6",    "neovim": "#54a23d",    "npm": "#C12127",
    "make": "#00aeff",      "mongod": "#589636",    "mongo": "#589636",
    "nodejs": "#7EBF00",    "node": "#7EBF00",      "ping": "#00aeff",
    "python": "#FFDF59",    "postgres": "#27527E",  "rails": "#CC0000",
    "ruby": "#CC342D",      "search": "#9CCC65",    "shell": "#00aeff",
    "testrpc": "#8A93B1",   "unzip": "#FD9126",     "vim": "#007f00",
    "yarn": "#2C8EBB",      "zip": "#FD9126",       "zsh": "#C5DB00",
}

# The color the tab label is actually drawn on: Ghostty's titlebar inherits the
# window background, which is Voltage's `bg`. Transcribed from
# .config/ghostty/config — themes/voltage.md lists this file as a consumer, so a
# palette change means a rebuild.
BACKGROUND = "#0F0D0E"

# iTerm2 chose those tints for its own tab bar, which is far lighter than this
# one, and several of them are simply unreadable here — measured against
# BACKGROUND, elixir's #440e60 is 1.36:1, erlang's #7f1831 1.92:1, postgres'
# #27527E 2.39:1. Anything below this floor gets lifted.
#
# 4.5:1 rather than the 3:1 that WCAG asks of graphical objects (SC 1.4.11):
# these are ~13px glyphs whose strokes are finer than text of the same size, and
# at 3:1 the three above are legible-but-muddy rather than legible. 4.5:1 is the
# AA bar for normal text, which is what they have to compete with in the label.
MIN_CONTRAST = 4.5


def rgb_of(hexstr):
    h = hexstr.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def hex_of(rgb):
    return "#%02X%02X%02X" % tuple(round(c * 255) for c in rgb)


def quantize(rgb):
    return tuple(round(c * 255) / 255 for c in rgb)


def _relative_luminance(rgb):
    r, g, b = (c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
               for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(rgb, other):
    a, b = _relative_luminance(rgb), _relative_luminance(other)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)


def legible(rgb, background):
    # Lightness only, in HSL, so hue and saturation come through untouched and a
    # lifted tint still reads as the brand color — postgres stays blue rather
    # than drifting grey. OKLab is the better perceptual space in general and
    # was tried first, but preserving a/b at higher lightness reads as *lower*
    # chroma: it turns elixir's purple into a dusty #9765BA where HSL gives
    # #AF48E4. Identity matters more than perceptual evenness for an icon.
    if contrast(rgb, background) >= MIN_CONTRAST:
        return rgb
    hue, light, sat = colorsys.rgb_to_hls(*rgb)

    # Search on 8-bit colors, not on the float ones. CPAL stores a byte per
    # channel, so a result that clears the floor in float space can round back
    # under it — that is the difference between 4.49:1 and 4.50:1 here, and it
    # would quietly make the constant a lie.
    def at(lightness):
        return quantize(colorsys.hls_to_rgb(hue, lightness, sat))

    lo, hi = light, 1.0  # white clears the floor from any hue on this background
    for _ in range(32):
        mid = (lo + hi) / 2
        if contrast(at(mid), background) < MIN_CONTRAST:
            lo = mid
        else:
            hi = mid
    # Rounding is not monotonic channel-by-channel, so bisection can land a step
    # short. Walk up until the byte values themselves clear it.
    while contrast(at(hi), background) < MIN_CONTRAST and hi < 1.0:
        hi = min(1.0, hi + 1 / 512)
    return at(hi)


# (source glyph, iTerm2 icon name, [(zsh case pattern, iTerm2 color key)])
#
# One group per *color*, not per icon: the font can only carry one color per
# glyph, so anywhere iTerm2 tints two commands differently off the same picture
# the group splits and the glyph is duplicated under a second codepoint. That is
# why `zsh`, `bash`, `fish` and `tcsh` are four lines of one terminal glyph.
#
# A `None` color key means iTerm2 has no tint for it either; those keep the
# plain Nerd Font codepoint and stay monochrome, dimming with the label the way
# they do today.
ICONS = [
    (0xE795, "shell", [
        ("zsh", "zsh"),
        ("bash", "bash"),
        ("fish", "fish"),
        ("tcsh", "shell"),
    ]),
    (0xE702, "git", [
        ("git|git-remote-ftp|git-remote-ftps|git-remote-http|git-remote-https", "git"),
    ]),
    # nvim takes vim's picture (Nerd Fonts only added a Neovim glyph at U+E6AE,
    # outside this font's charset) but iTerm2's own neovim green.
    (0xE62B, "vim", [
        ("vim|vi|Vim", "vim"),
        ("nvim", "neovim"),
    ]),
    (0xF044, "nano/code", [("nano|pico", None)]),
    (0xE632, "emacs", [("emacs|Emacs", "emacs")]),
    (0xF02D, "read", [("tail|less|more", None)]),
    (0xF002, "search", [("grep|egrep|fgrep|search|find|lookup", "search")]),
    (0xF0E4, "monitor", [("top|htop|iftop", None)]),
    (0xF0A1, "bullhorn", [("ping", "ping")]),
    (0xF019, "curl", [("curl", "curl")]),
    (0xF0AC, "http", [("wget|http", None)]),
    (0xF308, "docker", [("docker|docker-compose", "docker")]),
    # iTerm2 tints `make` and nothing else in this group.
    (0xF085, "compile", [
        ("make|gmake", "make"),
        ("cc|ccache|clang|gcc|xcodebuild", None),
    ]),
    (0xF1C6, "zip", [
        ("zip|unzip|gzip|gunzip|gzcat|bzip2|bunzip2|tar|gz|winzip|zar", "zip"),
    ]),
    (0xE718, "nodejs", [("node", "node")]),
    (0xE71E, "npm", [("npm|npx", "npm")]),
    (0xF1B2, "yarn", [("yarn|yarnpkg", "yarn")]),
    (0xE73D, "php", [("php|composer|composer.phar", None)]),
    (0xE73C, "python", [
        ("python|python[0-9.]*|Python|ipython|IPython|apython|pip|easy_install", "python"),
    ]),
    (0xE739, "ruby", [("ruby|irb|rake|sidekiq", "ruby")]),
    (0xE769, "perl", [("perl", None)]),
    (0xE738, "java", [("java|javac", None)]),
    (0xE627, "go", [("go", None)]),
    (0xE768, "clojure", [("lein|planck|lumo", None)]),
    (0xE62D, "elixir", [("elixir|elixirc|iex|mix", "elixir")]),
    (0xE7B1, "erlang", [
        ("beam|beam.smp|dialyzer|epmd|erl|erlc|escript|run_erl|to_erl", "erlang"),
    ]),
    # U+FCB9 is v2-only: Nerd Fonts v3 moved the Material range to U+F0001+, so
    # this is the one entry a source-font upgrade would break. The build fails
    # loudly rather than emitting a blank if it goes missing.
    (0xFCB9, "ethereum", [
        ("ethereum|testrpc", "ethereum"),
        ("geth", "geth"),
    ]),
    (0xE77B, "heroku", [("heroku", "heroku")]),
    (0xE76E, "postgres", [("postgres|psql", "postgres")]),
    (0xF1C0, "database", [
        ("mongo|mongod|mongodb", "mongo"),
        ("mysql|sqlite3|postmaster|pgbench|pg_dump|pg_dumpall|pg_restore|pg_upgrade"
         "|redis-cli|redis-server|redis-sentinel|redis-benchmark|redis-check-aof"
         "|redis-check-rdb", None),
    ]),
    (0xF069, "claude_code", [("claude", "claude_code")]),
]

# The unmapped-command fallback. Deliberately still an icon rather than nothing:
# a tab that sometimes has an icon and sometimes doesn't reads as broken.
FALLBACK = (0xE795, "shell")

# Plane 16 (Supplementary Private Use Area-B). Nothing else will ever claim it —
# Nerd Fonts v3 reaches only to U+F0001+ — so a source-font upgrade can add
# glyphs without colliding. Reaching it needs a format 12 cmap subtable; Hack
# ships only format 4, which is BMP-only.
PRIVATE_BASE = 0x100000


def main():
    src = next((p for p in SOURCE_CANDIDATES if p.exists()), None)
    if src is None:
        sys.exit("No source font found. Tried:\n  " +
                 "\n  ".join(str(p) for p in SOURCE_CANDIDATES))
    print(f"source: {src}")

    font = TTFont(src)
    cmap = font.getBestCmap()
    glyf, hmtx = font["glyf"], font["hmtx"]

    def duplicate(src_name, new_name):
        # glyf.__setitem__ appends to glyf.glyphOrder for us; hmtx does not.
        glyf[new_name] = deepcopy(glyf[src_name])
        hmtx[new_name] = hmtx[src_name]

    palette, colr, extra_cmap, rows = [], {}, {}, []
    next_cp = PRIVATE_BASE

    def assign(glyph_cp, icon, pattern, color_key):
        nonlocal next_cp
        if glyph_cp not in cmap:
            sys.exit(f"{src.name} has no glyph at U+{glyph_cp:04X} (icon {icon!r}). "
                     "A Nerd Fonts version change moved it; fix ICONS.")
        if color_key is None:
            rows.append((pattern, glyph_cp, icon, None, None))
            return
        source = rgb_of(COLORS[color_key])
        lifted = legible(source, rgb_of(BACKGROUND))
        cp, next_cp = next_cp, next_cp + 1
        idx = len(palette)
        base, layer = f"tabicon{idx}", f"tabicon{idx}.layer"
        duplicate(cmap[glyph_cp], base)   # kept as the non-COLR fallback outline
        duplicate(cmap[glyph_cp], layer)  # the one drawn, in palette color `idx`
        extra_cmap[cp] = base
        colr[base] = [(layer, idx)]
        palette.append(tuple(lifted) + (1.0,))
        rows.append((pattern, cp, icon, hex_of(lifted),
                     None if lifted == source else COLORS[color_key].upper()))

    for glyph_cp, icon, groups in ICONS:
        for pattern, color_key in groups:
            assign(glyph_cp, icon, pattern, color_key)
    assign(FALLBACK[0], FALLBACK[1], "*", FALLBACK[1])

    # A format 12 subtable supersedes format 4 wherever both are present, so it
    # has to carry every existing mapping as well as the new ones.
    sub = CmapSubtable.newSubtable(12)
    sub.platformID, sub.platEncID, sub.format = 3, 10, 12
    sub.reserved, sub.length, sub.language, sub.nGroups = 0, 0, 0, 0
    sub.cmap = {**cmap, **extra_cmap}
    font["cmap"].tables.append(sub)

    font.setGlyphOrder(glyf.glyphOrder)
    font["CPAL"] = buildCPAL([palette])
    font["COLR"] = buildCOLR(colr, version=0)

    # Rename so this installs *beside* the real Hack Nerd Font rather than
    # fighting it for the family name — only window-title-font-family uses it.
    for rec in font["name"].names:
        if rec.nameID in (1, 3, 4, 6, 16):
            rec.string = (rec.toUnicode()
                          .replace("Hack Nerd Font", FAMILY)
                          .replace("HackNerdFont", "HackNerdFontColor"))

    font.save(FONT_OUT)
    print(f"wrote {FONT_OUT.relative_to(REPO)} "
          f"({FONT_OUT.stat().st_size // 1024} KB, {len(palette)} colored glyphs)")

    # Align the assignment column across the patterns that fit; the handful of
    # very long ones wrap to the next line onto the same column, the way the
    # hand-written table this replaces did.
    WRAP = 64
    width = max(len(p) for p, *_ in rows if len(p) <= WRAP) + 2
    cases = []
    for pattern, cp, icon, color, source in rows:
        if color is None:
            note = f"# {icon}, no iTerm2 tint"
        elif source is None:
            note = f"# {icon}, {color}"
        else:
            note = f"# {icon}, {color} (iTerm2 {source}, lifted)"
        assign = f"_tabtitle_glyph=$'\\U{cp:08X}' ;;  {note}"
        if len(pattern) > WRAP:
            cases.append(f"    {pattern})\n{'':<{width + 4}}{assign}")
        else:
            cases.append(f"    {pattern + ')':<{width}}{assign}")

    ZSH_OUT.write_text(
        "# Generated by fonts/build-tab-icons.py — do not edit.\n"
        "#\n"
        "# Command -> icon codepoint. The codepoints are plane-16 private use and\n"
        "# only resolve under the Hack Nerd Font Color face that script also builds;\n"
        "# each one is a Nerd Font glyph with an iTerm2 tint baked into the font's\n"
        "# COLR table, because Ghostty gives the whole tab label a single color.\n"
        "# Entries with no iTerm2 tint keep their plain Nerd Font codepoint.\n"
        "#\n"
        "# Written as a case rather than an associative array so it costs nothing at\n"
        "# startup: the patterns compile into the .zwc and are only walked in preexec.\n"
        "_tabtitle_glyph_for() {\n"
        "  emulate -L zsh\n"
        "\n"
        "  case $1 in\n"
        + "\n".join(cases) + "\n"
        "  esac\n"
        "}\n"
    )
    print(f"wrote {ZSH_OUT.relative_to(REPO)} ({len(rows)} patterns)")

    lifted = [(icon, source, color) for _, _, icon, color, source in rows if source]
    if lifted:
        bg = rgb_of(BACKGROUND)
        print(f"lifted to {MIN_CONTRAST}:1 against {BACKGROUND}:")
        for icon, source, color in dict.fromkeys(lifted):
            before, after = contrast(rgb_of(source), bg), contrast(rgb_of(color), bg)
            print(f"  {icon:<12} {source} {before:5.2f}:1  ->  {color} {after:5.2f}:1")


if __name__ == "__main__":
    main()
