# Voltage

The palette this shell is themed on. Warm near-black background, electric
magenta/lime accents.

Derived from the Ghostty palette in `.config/ghostty/config`, which was itself
ported from the old `.config/rio/config.toml`. Two things were wrong with that
palette as an ANSI set, and are fixed here:

- **Slot 1 held magenta, not red.** `#eb43f4` sat in the red slot, so anything
  emitting ANSI red (test failures, `git status` deletions, `grep` matches)
  came out pink. Slot 1 is now a real red, and the magenta moved to slot 5
  where it belongs.
- **Blue and cyan were the same color.** `#5cc9f5` was in slots 4, 12 and 14,
  so blue and bright-cyan were indistinguishable. Slot 6/14 is now the
  distinct cyan `#17d5df` that Rio already had but never used in the bright
  set.

Nothing else moved: every color below except `red` appeared somewhere in the
Rio/Ghostty config already.

## Base

| Role       | Hex       | Notes                                        |
| ---------- | --------- | -------------------------------------------- |
| `bg`       | `#0F0D0E` | Warm near-black. Ghostty draws it at 75% + blur. |
| `bg-alt`   | `#1C191A` | Ghostty's selection background.               |
| `sel`      | `#2A2427` | Panel/selection fill. Lifted off `bg-alt`, which is too dark to read as a highlight against a blurred backdrop. |
| `black`    | `#393A3D` | ANSI 0.                                       |
| `subtle`   | `#6B6B6B` | ANSI 8. Comments, ghost text, borders.        |
| `fg`       | `#E7E7E7` | ANSI 7. Body text.                            |
| `white`    | `#F8F8F8` | ANSI 15.                                      |

## Accents

| Role      | Normal (0-7) | Bright (8-15) |
| --------- | ------------ | ------------- |
| `red`     | `#FF4D5E`    | `#FF6B7A`     |
| `green`   | `#B3E053`    | `#C6EE6E`     |
| `yellow`  | `#F9E906`    | `#F8F079`     |
| `blue`    | `#5CC9F5`    | `#7FD8F8`     |
| `magenta` | `#EB43F4`    | `#F712FF`     |
| `cyan`    | `#17D5DF`    | `#4EE3EC`     |

## Extras

Not ANSI slots — used where a module needs to stay distinct from everything
above.

| Role     | Hex       | Notes                                            |
| -------- | --------- | ------------------------------------------------ |
| `orange` | `#FF9A4D` | The palette has no warm mid-tone; several starship modules and fsh's variables/precommands need one that reads as neither red nor yellow. |
| `violet` | `#6638F0` | Rio's slot 5. Too dark on `bg` for text — used only as a fill or for large glyphs, never for prose. |
| `accent` | `#F712FF` | Cursor. Same value as bright magenta.            |

## Where it's applied

All of these have to agree or the shell looks patched together:

| Tool                     | File                              |
| ------------------------ | --------------------------------- |
| Ghostty (terminal)       | `.config/ghostty/config`          |
| starship (prompt)        | `.config/starship.toml`           |
| fzf                      | `zsh/extra/fzf.zsh`               |
| vivid → `LS_COLORS`      | `.config/vivid/themes/voltage.yml` |
| bat + delta              | `.config/bat/themes/Voltage.tmTheme` |
| fast-syntax-highlighting | `.config/fsh/voltage.ini`         |
| eza, autosuggestions     | `.zshrc`                          |
| man (via bat)            | `.zshrc` — `MANPAGER`             |
| atuin (owns Ctrl-R)      | `.config/atuin/themes/voltage.toml` |
| lazygit                  | `.config/lazygit/config.yml`      |
| yazi                     | `.config/yazi/theme.toml`         |
| superfile (`spf`)        | `.config/superfile/theme/voltage.toml` |
| btop                     | `.config/btop/themes/voltage.theme` |
| glow                     | `.config/glow/voltage.json`       |
| Neovim + LunarVim        | `.config/voltage.nvim/`           |
| iris (completion overlay)| `.config/iris/theme.toml`         |
| Claude Code (via tweakcc) | `.config/tweakcc/config.json`, the `voltage-dark` and `voltage-dark-ansi` themes |

### Claude Code picks its syntax colors from the theme's id

There are two Voltage themes because Claude Code has no setting for code
colors. Its highlighter (code blocks and diffs) reads the theme's id and
branches on two substrings, and that is the only control there is:

| Id contains     | Syntax colors                                   |
| --------------- | ----------------------------------------------- |
| `ansi`          | ANSI slots 8 and 10-14, plus slot 7 for plain code |
| `dark`, no `ansi` | Monokai Extended, hard-coded in the binary    |
| neither         | GitHub's light theme: dark gray text, unreadable on `bg` |

So the ids are load-bearing and a rename changes the colors:

- **`voltage-dark-ansi`** ("Voltage (ANSI syntax)") is the one whose code
  matches. The slots resolve through the Ghostty palette, so keywords come out
  bright magenta, strings bright green, types bright cyan, numbers bright blue,
  function names bright yellow and comments `subtle`, and they follow the
  terminal the way `git` and `rg` do. It needs `dark` as well as `ansi`:
  without it, plain code is drawn in slot 0, which is `black`.
- **`voltage-dark`** ("Voltage") is the same interface with Monokai code
  colors. It exists for the diff fills, below.

The cost of the `ansi` id is that the highlighter stops emitting 24-bit color
and rounds every `rgb()` it is given to the 256-color cube. The mixed diff
fills round to neutral grays (`rgb(64,76,35)` becomes gray 237), so
`voltage-dark-ansi` uses the four cube colors that survive the rounding
unchanged: `rgb(0,95,0)` and `rgb(0,135,0)` for added lines and words,
`rgb(95,0,0)` and `rgb(135,0,0)` for removed. Those are the same slots stock
Claude Code falls back to on a 256-color terminal, and they are the only
values in either theme that owe nothing to the palette.

Rejected: patching the Monokai table in the binary to Voltage hex, which would
give matching code and the mixed fills in one theme. tweakcc has no patch for
it, so it would be a hand-kept byte patch that every Claude Code update could
break without a sign.

This was read out of Claude Code 2.1.314 (`ge()`, `Y()` and `Q()` in the
highlighter chunk). Check it again if code colors change after an update.

### Claude Code's themes hold values that aren't in the tables

tweakcc themes take only `rgb()` or `ansi:` values, so the hex above is written
as decimal triplets there and a search for a hex code will not find them. The
themes also need 13 colors the palette doesn't have, each mixed from two values
that are in it. Recompute them when either source moves:

- **Diff fills** (`diffAdded*`, `diffRemoved*`), in `voltage-dark` only, are
  `green` and `red` mixed into `bg` at 30% (line), 50% (word), 18% (dimmed
  line) and 35% (dimmed word).
  Claude Code draws diff text on top of these, and the accents at full strength
  would leave that text unreadable.
- **`inactive` and `promptBorderShimmer`** are `#A9A9A9`, halfway between
  `subtle` and `fg`. Claude Code sets most of its hint text in `inactive`, and
  `subtle` is too dim for that much reading.
- **`autoAccept`, the purple subagent and `rainbow_indigo`** are `#A388F6`,
  `violet` mixed 40% toward white, because `violet` is too dark on `bg` for
  text. `rainbow_indigo_shimmer` is the same mix at 60%.
- **`claudeShimmer` and `rainbow_violet_shimmer`** are `magenta` mixed 40%
  toward white, and `rainbow_orange_shimmer` is `orange` mixed 35% toward
  white. A shimmer has to be lighter than its base, and neither color has a
  lighter partner in the palette (bright magenta is more saturated, not lighter).

The theme's `background` key is `cyan`, not `bg`. Stock Claude Code sets it to
a cyan too, so it is an accent despite the name; the terminal still draws the
real background.

A change reaches Claude Code only after `tweakcc --apply --yes` and a restart.

### What deliberately has no entry

`rg`, `git`, `jq` and `tree` are missing from that table on purpose. They emit
**ANSI indices** (`31`, `1;34`) rather than hex, so they already resolve through
the Ghostty palette at the top of this file and track it for free — a `git`
deletion is slot 1, which is why moving magenta out of the red slot fixed those
without anyone touching git's config.

Writing explicit hex for them would make things *worse*, not better: it would
pin them to these values and stop them following the terminal, which is the
one mechanism here that cannot drift.

Neovim is the opposite case and is why it gets a row rather than an exemption.
It sets `termguicolors`, so it emits 24-bit hex and resolves nothing through
the Ghostty palette — the editor is the largest surface on screen and the one
that would drift hardest if left to a stock theme. `.config/voltage.nvim/`
therefore spells out every highlight group. The one thing it *does* hand back
to the palette is `terminal_color_0..15`, so `:terminal` buffers and anything
drawn inside them resolve through the table at the top of this file.

That directory is a colorscheme in Neovim's own plugin shape — `colors/` plus
`lua/` — rather than a file inside either editor's config, because there are
two editors here (`.config/nvim` and `.config/lvim`) and a copy each is exactly
the drift this document exists to prevent. Both put it on their runtimepath and
`:colorscheme voltage` resolves out of it. It is also the only thing the two
configs share.

Two tools also need forcing flags rather than colors. Anything rendering inside
an fzf preview or a pipe has to be told to keep color — `--color=always` for
`fd`/`eza`/`bat`, and `--icons=always` for eza specifically, whose bare
`--icons` silently emits nothing when stdout is not a terminal.

`LS_COLORS` is cached (see `zcache_value` in `.zshrc`); run `zcache_clear`
after editing the vivid theme, since mtime invalidation only sees a new vivid
binary, not new arguments or a changed theme file.

### `LS_COLORS` is the one row with an opt-out

`.zshrc` reads `$LS_COLORS_SOURCE`, which selects between the vivid/Voltage
theme above (`vivid`, the default) and `trapd00r`, a second database cloned by
`install.sh` to `~/.local/share/LS_COLORS`. trapd00r's carries its own
256-colour scheme, so selecting it breaks the "all of these have to agree"
guarantee this table describes — file listings, completion menus and fzf-tab
previews stop matching the prompt, fzf, bat and `EZA_COLORS`. That is the point
of it (a side-by-side comparison), not a defect, but nothing else in this repo
tracks those colours and this table stays true only for the default.

```sh
LS_COLORS_SOURCE=trapd00r zsh   # one shell, nothing on disk changes
```

bat and fast-syntax-highlighting both need a build step after an edit —
`install.sh` runs both, or by hand:

```sh
bat cache --build
fast-theme XDG:voltage
```
