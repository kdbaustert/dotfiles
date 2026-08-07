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
