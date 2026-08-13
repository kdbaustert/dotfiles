# AGENTS.md

Personal macOS dotfiles (Apple silicon). Everything here is deployed into `$HOME`
as **symlinks** by `install.sh`. `README.MD` documents the repo for a human
installing it; this file is the working contract for an agent editing it.

## The one rule that breaks everything else

`~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`,
`~/.prettierrc`, `~/.claude/CLAUDE.md` and every `~/.config/<tool>` entry are
symlinks into this repo. **Edit the file in `~/dotfiles`.** Never write to the
`$HOME` path, and never run a tool that rewrites a shell RC in place — it will
silently edit the tracked file. `iris setup` and `iris uninstall` are the known
offenders; don't run either.

## Layout

| Path                  | Contents                                                        |
| --------------------- | --------------------------------------------------------------- |
| `.zshrc` / `.zprofile` / `.zshenv` | Shell entry points, symlinked to `$HOME`           |
| `zsh/`                | `aliases.zsh`, `functions.zsh`, `zinit.zsh`, `extra/` snippets    |
| `.config/`            | Every entry is symlinked to `~/.config/<name>`                    |
| `homebrew/Brewfile`   | The package set                                                   |
| `setup/`              | Opt-in scripts (`SETUP_SCRIPTS="npm composer" ./install.sh`)      |
| `themes/voltage.md`   | Canonical palette + the list of files that carry it               |
| `clamav/`, `iterm/`, `obsidian/` | App-specific config                                    |
| `.claude/CLAUDE.md`   | Global Claude Code instructions (the only deployed `.claude/` file) |

Two Neovim configs, deliberately independent: `.config/nvim` (hand-rolled,
lazy.nvim) and `.config/lvim` (LunarVim). They share only `.config/voltage.nvim`,
the colorscheme, which both put on their runtimepath. Never fold one into the
other or copy the palette into either.

## Adding or changing config

- A new tool config goes in `.config/<tool>/` — `install.sh` links every
  `.config/*` entry automatically, so no installer change is needed.
- A new **root-level** dotfile must be added to the `for f in ...` list in the
  "Symlinking dotfiles" section of `install.sh`, or it never gets deployed.
- Anything that leaves a file outside this repo (a cache build, a `launchctl`
  bootstrap, a `defaults write`) needs a step in `install.sh` — and that step must
  be **idempotent**, guarded, and print via `info`/`success`/`warning`/`error`.
- Removing a config: `install.sh` already sweeps dangling `~/.config` symlinks
  that point into this repo. Root-level retirements go in the "Retired links"
  list instead.

## Do not run `install.sh` to test a change

It asks for sudo, edits `/etc/pam.d/sudo_local`, runs `brew bundle`, downloads
~120MB of ClamAV signatures, and loads LaunchAgents. Verify narrowly instead:

```sh
bash -n install.sh && shellcheck install.sh   # installer + setup/*.sh (bash)
zsh -n .zshrc                                 # zsh files: parse only
zsh -ic exit                                  # full interactive load
time zsh -i -c exit                           # startup cost — it is budgeted
stylua --check .config/nvim .config/lvim .config/voltage.nvim
```

Startup latency is a first-class constraint here: plugins are turbo-deferred in
`zsh/zinit.zsh`, tool `init` output is cached via the `zcache` helper defined
near the top of `.zshrc`, and the file byte-compiles itself at the end. Anything
you add to the critical path should be measured, and a new `eval "$(tool init
zsh)"` should go through `zcache`, not straight into `.zshrc`.

## Style

`.editorconfig` governs: 2-space indent, LF, UTF-8, final newline, no trailing
whitespace (CSS/SCSS use tabs at 4). Shell scripts in `setup/` and `install.sh`
declare a **bash** shebang and use bash arrays — they are run directly, never via
`sh`.

**Comments here explain *why*, and are expected to be long.** This repo documents
rejected alternatives inline — why `pay-respects` isn't a Homebrew formula, why
`LS_COLORS` isn't a zinit plugin, why the ClamAV download runs in the background.
When you change one of those decisions, update the comment that justified the old
one. A change with no rationale attached does not match this codebase.

## Generated vs. tracked

Do not commit: `*.zwc` (byte-compiled zsh, machine-specific),
`.config/fsh/secondary_theme.zsh`, `.zsh_history`.

Do commit, even though a tool generates them: `.config/fsh/current_theme.zsh`
(built from our `voltage.ini`; it's what themes a fresh machine) and both
`lazy-lock.json` files (they pin the plugin sets for `:Lazy restore`).

## Colors

Every palette change starts at `themes/voltage.md` — it holds the canonical hex
values and lists every file that transcribes them (ghostty, starship, fzf, vivid,
bat, btop, lsd, atuin, fsh, yazi, glow, `voltage.nvim`). Update the doc and all
consumers together; drift between two copies of the palette is the exact failure
that file exists to prevent. `bat` and fast-syntax-highlighting compile their
themes into caches and need the corresponding `install.sh` steps re-run.

## Git

Commits are SSH-signed through 1Password. Don't disable signing, don't set a
per-repo `user.email`, and don't commit or push unless asked.
