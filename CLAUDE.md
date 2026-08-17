# dotfiles

Personal macOS dotfiles (Apple silicon). Everything here is deployed into `$HOME`
as **symlinks** by `install.sh`. `README.MD` documents the repo for a human
installing it; this file is the working contract for an agent editing it.

The rules below used to live in a sibling `AGENTS.md` that this file pulled in
with an `@AGENTS.md` import — vendor-neutral name, one copy, read directly by
tools that look for it. That split is gone by choice: Claude Code is the only
agent that edits this repo, the import was a silent failure mode (delete the line
and the rules go missing rather than erroring), and one file beats two that have
to stay in sync. The *global* file in `.claude/` was merged the same way, for the
same reasons — there is no `AGENTS.md` at either scope any more.

Not to be confused with `.claude/CLAUDE.md`, which is the *global* instruction
file staged here for deployment to `~/.claude/` — it is not about this repo.

## The one rule that breaks everything else

`~/.zshrc`, `~/.zprofile`, `~/.profile` (a second link to `.zprofile`),
`~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`, `~/.prettierrc`,
`~/.claude/CLAUDE.md` and every `~/.config/<tool>` entry
are symlinks into this repo. **Edit the file in `~/dotfiles`.** Never write to the
`$HOME` path. `~/.hushlogin` is the one exception — `install.sh` `touch`es it
rather than linking it, because only its existence is ever read.

The corollary is the real hazard: **never run a tool that rewrites one of these
files in place**, because it lands in the tracked file with no indication it did.
Known offenders:

- `iris setup` / `iris uninstall` — rewrite the shell RC. Don't run either.
- `abbr add` / `abbr erase` — rewrite `zsh/abbreviations`, which is tracked, and
  drop every comment in it (its own header says so). Editing that file by hand is
  the way to keep the section breaks; `abbr` is for throwaway experiments.

## Layout

| Path                  | Contents                                                        |
| --------------------- | --------------------------------------------------------------- |
| `.zshrc` / `.zprofile` / `.zshenv` | Shell entry points, symlinked to `$HOME`           |
| `zsh/`                | `aliases.zsh`, `functions.zsh`, `zinit.zsh`, `extra/` snippets    |
| `zsh/abbreviations`   | zsh-abbr's store, read via `$ABBR_USER_ABBREVIATIONS_FILE`        |
| `.config/`            | Every entry is symlinked to `~/.config/<name>`                    |
| `.config/git/`        | `ignore` (global excludes) and `allowed_signers` (SSH signing)     |
| `homebrew/Brewfile`   | The package set                                                   |
| `setup/`              | Opt-in scripts (`SETUP_SCRIPTS="npm composer" ./install.sh`)      |
| `themes/voltage.md`   | Canonical palette + the list of files that carry it               |
| `clamav/`, `iterm/`, `obsidian/` | App-specific config                                    |
| `.claude/CLAUDE.md`   | Global Claude Code instructions (the only file here that deploys) |

The two `.config/git/` files reach git by different routes, which matters when
one of them appears not to work: `allowed_signers` is named explicitly by
`.gitconfig`'s `allowedSignersFile`, while `ignore` has no `core.excludesFile`
pointing at it at all — git reads `$XDG_CONFIG_HOME/git/ignore` on its own, so
the symlink is the whole wiring.

`.claude/` is tracked in full but only partly deployed: `install.sh` links
`CLAUDE.md` and nothing else, so `themes/my-theme.json` rides along for reference
and is applied by hand. The installer also sweeps the retired
`~/.claude/AGENTS.md` link on re-run.

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
bash -n install.sh && shellcheck install.sh setup/*.sh   # bash: parse, then lint
for f in .zshenv .zprofile .zshrc zsh/*.zsh zsh/extra/*.zsh; do
  zsh -n "$f" || echo "FAIL $f"                          # zsh: parse only
done
zsh -ic exit                                  # full interactive load
time zsh -i -c exit                           # startup cost — it is budgeted
stylua --check .config/nvim .config/lvim .config/voltage.nvim
```

Both file lists are load-bearing, and both used to be shorter than they needed
to be. `shellcheck` never sees `setup/*.sh` on its own — those are invoked by
variable name from the `SETUP_SCRIPTS` loop, which it cannot resolve statically,
so they have to be named on the command line. And `zsh -n` parses exactly *one*
file: extra arguments become positional parameters and are silently never read
(`zsh -n .zshenv /nonexistent` exits 0), which is why this is a loop and not a
list. It has to be, because `.zshrc` `source`s `zsh/extra/cache.zsh`,
`zinit.zsh`, `functions.zsh`, `aliases.zsh` and four more `extra/` snippets at
*runtime* — a syntax error in any of them sails past `zsh -n .zshrc` and only
surfaces in `zsh -ic exit`.

`shellcheck` currently exits 1 on a clean tree: two SC2015 `info`s on the
deliberate `cmd && success || warning` lines in `install.sh` (both are
best-effort steps where the "C may run when A is true" caveat is acceptable).
Read the findings, don't chase the exit status, and don't rewrite those two lines
into `if`/`else` just to silence it.

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

`.claude/settings.local.json` is also uncommittable here, but not via `.gitignore`
— the exclude lives in `.config/git/ignore` as `**/.claude/settings.local.json`,
which this repo deploys and is therefore subject to. So `git status` is clean with
that file sitting untracked in the tree; `git check-ignore -v <path>` is what tells
you which rule caught something.

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
