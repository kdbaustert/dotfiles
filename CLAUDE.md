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
`~/.claude/CLAUDE.md`, `~/.claude/hooks/notify.sh`, `~/.claude/statusline.sh`,
every `~/.claude/skills/<skill>` directory and every `~/.config/<tool>` entry
are symlinks into this repo. **Edit the file in `~/dotfiles`.** Never write to the
`$HOME` path. Two exceptions: `~/.hushlogin`, which `install.sh` `touch`es
rather than links because only its existence is ever read, and
`~/Library/Fonts/HackNerdFontColor-Regular.ttf`, which is **copied**, because
CoreText does not register a symlinked font (measured — see the *Tab icon font*
section of `install.sh`). That one is the only place where editing the repo file
is not enough on its own: re-run `install.sh` to push the new bytes across.

The corollary is the real hazard: **never run a tool that rewrites one of these
files in place**, because it lands in the tracked file with no indication it did.
Known offenders:

- `iris setup` / `iris uninstall` — rewrite the shell RC. Don't run either.
- `abbr add` / `abbr erase` — rewrite `zsh/abbreviations`, which is tracked, and
  drop every comment in it (its own header says so). Editing that file by hand is
  the way to keep the section breaks; `abbr` is for throwaway experiments.
- `brew` — appends a `[safe] directory` pair to `~/.gitconfig` with
  `git config --global --add` every time it hits dubious-ownership on a tap, so
  the block regrows a copy at a time and shows up as an unexplained diff. Nothing
  breaks — extra entries are inert — but collapse it back to one pair per path
  when you see it; the comment above the block carries the recipe. This is also
  why `git config --global` is the wrong way to change anything here: it rewrites
  the tracked file, and it can replace the symlink rather than follow it.

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
| `fonts/`              | The tab-icon color font and the script that builds it             |
| `clamav/`, `iterm/`, `obsidian/` | App-specific config                                    |
| `.claude/CLAUDE.md`   | Global Claude Code instructions                                   |
| `.claude/hooks/`      | `notify.sh`, the Notification hook (terminal-notifier banner)     |
| `.claude/statusline.sh` | The status line — plan usage, context, model, on every render   |
| `.claude/skills/`     | Skills, one dir per skill; `plain/` is vendored from upstream      |

The two `.config/git/` files reach git by different routes, which matters when
one of them appears not to work: `allowed_signers` is named explicitly by
`.gitconfig`'s `allowedSignersFile`, while `ignore` has no `core.excludesFile`
pointing at it at all — git reads `$XDG_CONFIG_HOME/git/ignore` on its own, so
the symlink is the whole wiring.

`.claude/` is tracked in full but only partly deployed: `install.sh` links
`CLAUDE.md`, `hooks/notify.sh`, `statusline.sh` and every directory under
`skills/`, so `themes/my-theme.json` rides along for reference and is applied by
hand. The installer also sweeps the retired `~/.claude/AGENTS.md` link on
re-run.

`skills/` is a loop over `skills/*`, not one `link` line per skill, for the same
reason `.config/*` is — a skill added here but not named in the installer would
silently never deploy, the exact failure mode that killed the `@AGENTS.md`
import. A skill is discovered by its *directory* containing a `SKILL.md`, so the
directory is what gets linked. The sweep alongside it removes only links that
point into this repo, so a skill installed by hand from elsewhere survives.

`skills/plain/` is vendored verbatim from
`petekp/claude-code-setup` (`skills/plain/SKILL.md`) — it is upstream's file,
not ours. Re-fetch with `gh api` and diff rather than editing in place; local
edits would be silently lost the next time it is refreshed.

`~/.claude/settings.json` is **not** tracked — it is mostly state Claude writes
itself (model, `enabledPlugins`, the atuin hooks), so a symlink would fight it.
That makes the two blocks wiring the deployed scripts up a manual step on a new
machine — one under `hooks`, one at the top level:

```json
"Notification": [{ "hooks": [{ "type": "command",
  "command": "$HOME/.claude/hooks/notify.sh" }] }]
```

```json
"statusLine": { "type": "command",
  "command": "$HOME/.claude/statusline.sh", "padding": 0 }
```

`Notification` is the only event hooked, on purpose — it fires when Claude is
blocked on you (a permission prompt, an idle question). `Stop` would banner
every turn, which is how you end up leaving Do Not Disturb on.

The status line is where the plan's usage windows live, because `/usage` only
answers when asked and the 5-hour window is usually already the reason you
asked. Three rows — session, week, context — each a bar plus a countdown, using
Claude Code's own names for the windows so the two never disagree. It re-runs on
every render, so it is held to the same latency budget as `.zshrc`: one `jq` and
nothing else, ~10ms measured. `padding: 0` puts it flush left against the prompt
box rather than indented by one column.

The same file carries the other untracked-but-load-bearing setting,
`"attribution": { "commit": "", "pr": "" }`, which is what actually strips the
`Co-Authored-By` trailer Claude Code would otherwise append to every commit.
`.claude/CLAUDE.md` states the rule as well, since only one of the two travels.

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
bash -n install.sh                            # bash: parse
shellcheck install.sh setup/*.sh \
  .claude/hooks/notify.sh .claude/statusline.sh   # ...then lint every one
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
so they have to be named on the command line. The two scripts under `.claude/`
have no caller in this repo at all — Claude Code runs them from `$HOME` — so
they are named for the same reason. And `zsh -n` parses exactly *one* file:
extra arguments become positional parameters and are silently never read
(`zsh -n .zshenv /nonexistent` exits 0), which is why this is a loop and not a
list. It has to be, because `.zshrc` `source`s `zsh/extra/cache.zsh`,
`zinit.zsh`, `functions.zsh`, `aliases.zsh` and six more `extra/` snippets at
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
(built from our `voltage.ini`; it's what themes a fresh machine), both
`lazy-lock.json` files (they pin the plugin sets for `:Lazy restore`), and both
outputs of `fonts/build-tab-icons.py` — `fonts/HackNerdFontColor-Regular.ttf`
and `zsh/extra/tabtitle-icons.zsh`. That last pair is committed because a fresh
machine has neither `fonttools` nor, until the Brewfile's font casks land, a
source Nerd Font to rebuild from; regenerating needs
`pip install fonttools && python3 fonts/build-tab-icons.py`, and both files must
be regenerated together — the codepoints in the `.zsh` only mean anything to the
`.ttf` built in the same run.

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
