# dotfiles

Personal macOS dotfiles (Apple silicon). Everything here is deployed into `$HOME`
as **symlinks** by `install.sh`. `README.MD` documents the repo for a human
installing it; this file is the working contract for an agent editing it.

Claude Code is the only agent that edits this repo and reads no `AGENTS.md` at
either scope, so the rules below live in this file rather than in a sibling one
pulled in by an `@AGENTS.md` import — a line whose deletion lost them silently.

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
| `zsh/os/`             | Per-OS shell config: `{macos,linux}-{env,interactive}.zsh`         |
| `zsh/abbreviations`   | zsh-abbr's store, read via `$ABBR_USER_ABBREVIATIONS_FILE`        |
| `.config/`            | Every entry is symlinked to `~/.config/<name>`                    |
| `.config/git/`        | `ignore` (global excludes) and `allowed_signers` (SSH signing)     |
| `homebrew/Brewfile`   | The package set (macOS)                                           |
| `arch/`               | `pkglist` + `aurlist`, the package set (Arch/Manjaro)              |
| `setup/lib.sh`        | Installer sections shared by `install.sh` and `install-linux.sh`  |
| `setup/`              | Opt-in scripts (`SETUP_SCRIPTS="npm composer" ./install.sh`)      |
| `.gitconfig-{macos,linux}` | Deployed to `~/.gitconfig-os`; git has no OS conditional     |
| `themes/voltage.md`   | Canonical palette + the list of files that carry it               |
| `fonts/`              | The tab-icon color font and the script that builds it             |
| `iterm/`, `obsidian/` | App-specific config                                            |
| `.claude/CLAUDE.md`   | Global Claude Code instructions                                   |
| `.claude/hooks/`      | `notify.sh`, the Notification hook (terminal-notifier / notify-send) |
| `.claude/statusline.sh` | The status line — plan usage, context, model, on every render   |
| `.claude/skills/`     | Skills, one dir per skill; `php-psr12/` is ours, five are vendored |
| `.claude/agents/`     | Custom subagents, one `.md` file per agent, ours                  |

The two `.config/git/` files reach git by different routes, which matters when
one of them appears not to work: `allowed_signers` is named explicitly by
`.gitconfig`'s `allowedSignersFile`, while `ignore` has no `core.excludesFile`
pointing at it at all — git reads `$XDG_CONFIG_HOME/git/ignore` on its own, so
the symlink is the whole wiring.

`.claude/` is tracked in full but only partly deployed: `install.sh` links
`CLAUDE.md`, `hooks/notify.sh`, `statusline.sh` and every file under `agents/`
and every directory under `skills/`, so `themes/my-theme.json` rides along for
reference and is applied by hand. The installer also sweeps the retired
`~/.claude/AGENTS.md` link on re-run.

`skills/` is a loop over `skills/*`, not one `link` line per skill, for the same
reason `.config/*` is — a skill added here but not named in the installer would
silently never deploy, the exact failure mode that killed the `@AGENTS.md`
import. The loop links every directory unconditionally, since a plain skill is
discovered by its *directory* containing a `SKILL.md`, while a directory that
also carries a `.claude-plugin/plugin.json` is discovered a second way — as a
full Claude Code plugin, auto-loading as `<name>@skills-dir` — and doesn't need
a `SKILL.md` of its own at all if its manifest points at `commands/` instead
(`code-review/` is exactly this: plugin.json + commands/code-review.md, no
SKILL.md). The sweep alongside the loop removes only links that point into this
repo, so a skill installed by hand from elsewhere survives.

Running `claude plugin list` from inside this repo will warn that
`frontend-design@skills-dir`/`code-review@skills-dir` are "shadowed" by a
same-named project-scope copy — that's `~/dotfiles/.claude/skills/<name>`
itself being visible twice (once as the deployed user-scope symlink target,
once as this repo's own `./.claude/skills/<name>` from the cwd). Harmless: the
user-scope one still loads, and it's only cosmetic double-counting that shows
up when your cwd happens to be this repo.

`agents/` is the same loop-not-list pattern, one level shallower: a subagent is
discovered by a `.md` file directly under `~/.claude/agents`, so the file itself
is what gets linked, not a containing directory. Each file's frontmatter sets
its own `model` — `quick-lookup` (haiku) and `researcher`/`code-reviewer`
(sonnet) for search and review work, `heavy-refactor` (opus) for multi-file
structural changes that need to hold more context to get right in one pass.
`CLAUDE_CODE_SUBAGENT_MODEL=sonnet` in `.zshenv` is only the fallback for
subagents with no `model:` of their own — the built-ins (Explore,
general-purpose, Plan) — not for these. `researcher` and `code-reviewer` also
carry `memory: project`, so findings persist per-repo across runs; the other
two don't — `quick-lookup` answers are too narrow to be worth retaining and
`heavy-refactor` runs are one-off enough that stale memory would be more
likely to mislead the next run than help it.

Only `php-psr12/` is ours; the other five skill directories are **vendored, not
ours**. `skills/plain/` comes from `petekp/claude-code-setup`
(`skills/plain/SKILL.md`); `skills/javascript-pro/` and `skills/swift-expert/`
come from `Jeffallan/claude-skills` (MIT), each with its `references/`
directory, because the SKILL.md's "Reference Guide" table is five dead links
without them. They are upstream's files. Re-fetch with `gh api` and diff rather
than editing in place; local edits would be silently lost the next time one is
refreshed:

```sh
gh api repos/Jeffallan/claude-skills/contents/skills/swift-expert/SKILL.md \
  -H 'Accept: application/vnd.github.raw'
```

`frontend-design/` and `code-review/` are also vendored, from
`anthropics/claude-code`'s own `plugins/frontend-design` and `plugins/code-review`
— copied whole (`.claude-plugin/plugin.json`, `README.md`, and either
`skills/frontend-design/SKILL.md` or `commands/code-review.md`), which is also
why they're full plugins and not just skills; see the note above
`claude plugin list`'s shadowing warning. Licensed under Anthropic's own
Commercial Terms of Service (`LICENSE.md` at that repo's root), not MIT like
the other two vendored skills. Re-fetch the same way:

```sh
gh api repos/anthropics/claude-code/contents/plugins/code-review \
  -H 'Accept: application/vnd.github.raw'
```

They were vendored from a local zip download rather than the marketplace
install this repo briefly used, because the `claude-plugins-official`
marketplace's mirror of both had drifted behind `main` — noticeably so for
`code-review`, which upstream had grown a `--comment`/inline-comment posting
step and named authors that the marketplace copy's `plugin.json` had genericized
to `"Anthropic"`.

Vendoring verbatim means two of them contradict the style rules in
`.claude/CLAUDE.md`. That is deliberate: correcting it in the file would be
thrown away by the next refresh, so it is recorded here instead. The global
rules win — these skills are reference material, not authority.

- `javascript-pro` writes every example with double quotes and semicolons, the
  opposite of the JS rule (single quotes, no semicolons, 80 cols, via
  `~/.prettierrc`). It states no quote rule anywhere, so this is
  conflict-by-example only — follow Prettier and ignore the examples'
  punctuation. Its workflow also mandates `eslint --fix` and Jest at 85%
  coverage; `eslint` and `prettier` are installed as pnpm globals but **`jest`
  is not installed at all**, so that step only applies when the repo being
  worked on ships it.
- `swift-expert` ends its workflow at `swift build` / `swift test`, which is not
  how Swift work finishes here — the global rule is `./build.sh --install`, and
  one of the projects uses a different build tool entirely. It also assumes
  SwiftUI and Swift 5.9+, while the projects here are AppKit at tools-version
  6.0. Take its concurrency, actor and protocol guidance; not its build steps.

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
asked. Four rows — session, week, Fable week, context — each a bar plus a
countdown, using Claude Code's own names for the windows so the two never
disagree. The Fable row is the odd one: Claude Code tracks that window and draws
it in `/usage` yet drops it from the object it hands the script (verified on
2.1.258 and again on 2.1.266), so the script keeps its own five-minute cache of
the usage endpoint at `~/.cache/claude-usage.json`, filled by a background
refresher and read by the same `jq` that renders. The script re-runs on every
render, so it is held to the same latency budget as `.zshrc`: one `jq` on the
hot path and nothing else, ~20ms measured with the cache read; the refresher
never runs in the foreground. `padding: 0` puts it flush left against the
prompt box rather than indented by one column.

The same file carries the other untracked-but-load-bearing setting,
`"attribution": { "commit": "", "pr": "" }`, which is what actually strips the
`Co-Authored-By` trailer Claude Code would otherwise append to every commit.
`.claude/CLAUDE.md` states the rule as well, since only one of the two travels.

Two Neovim configs, deliberately independent: `.config/nvim` (hand-rolled,
lazy.nvim) and `.config/lvim` (LunarVim). They share only `.config/voltage.nvim`,
the colorscheme, which both put on their runtimepath. Never fold one into the
other or copy the palette into either.

## macOS and Linux

The repo deploys to an Apple-silicon Mac and to Arch/Manjaro. One tracked file
per setting, never two — the split happens at three different layers depending
on *why* the setting differs, and picking the wrong layer is how this stops
working:

1. **Make it portable first.** A setting that can be expressed the same way on
   both is not a platform problem. `.gitconfig`'s `editor = nvim` (was an
   absolute `/opt/homebrew/bin/nvim`) and `extract()`'s `${commands[7zz]:-7z}`
   are the examples — no branch at all, and neither file knows what OS it is on.
2. **Same knob, different value → inline `if [[ $DOTFILES_OS == macos ]]`**, in
   the shared file, with both values visible to each other. `PNPM_HOME` in
   `.zprofile` is the model. Splitting a *pair* across two files is the palette
   drift this repo warns about everywhere else: one side gets updated, the other
   silently doesn't.
3. **Exists on one platform only → `zsh/os/<os>-{env,interactive}.zsh`.** The
   Homebrew environment, FlyEnv, the LaunchServices aliases, the `pbcopy`/`open`
   shims. There is no pair to keep visible, and wrapping forty lines in an `if`
   to no-op them just makes the other platform's reader scroll. The branch then
   exists once, at the `source` line, instead of a dozen times.

`$DOTFILES_OS` is set in `.zshenv` (`macos` / `linux` / `unknown`) because that
is the only file every zsh sources. There are exactly two dispatch points:
`.zprofile` sources `<os>-env.zsh` **last** — `macos-env.zsh` prepends FlyEnv to
`$path` and has to stay ahead of the array and the overrides block — and
`.zshrc` sources `<os>-interactive.zsh` after `aliases.zsh` and at the end of the
tool-integration block, so its `command_not_found_handler` is the last one
defined. Both placements are load-bearing; the comments at each say so.

A file format with no conditional of its own is the fourth case, and it has to
be resolved at deploy time instead: `.gitconfig` carries `[include] path =
~/.gitconfig-os`, and each installer symlinks that at `.gitconfig-macos` or
`.gitconfig-linux`. Only put a setting there if it genuinely cannot be portable
— today that is one line, the 1Password `op-ssh-sign` path.

`install.sh` (macOS) and `install-linux.sh` (Arch) are siblings, not forks.
Everything they do identically lives in `setup/lib.sh` and is called from both;
the symlink section alone is ~120 lines and grows every time a skill, an agent
or a `.config` entry is added, so two copies would drift within a week. If a
function in `lib.sh` ever needs an `if macos` inside it, that is the signal it
belongs to the callers instead.

Two terminal configs were deliberately left macOS-shaped: `.config/ghostty/config`
(`macos-titlebar-style`, `window-colorspace`, `font-thicken` are no-ops in the
GTK build) and `.config/rio/config.toml` (`navigation.mode = "NativeTab"` and
`renderer.backend = "Metal"` need changing by hand on Linux). Neither app has an
OS-conditional include, and inventing values that could not be verified against a
running Linux copy would have been worse than saying so here.

## Adding or changing config

Every symlink now lives in `link_dotfiles()` in `setup/lib.sh`, not in either
installer — that is the one place to change, and changing it deploys to both
machines at once.

- A new tool config goes in `.config/<tool>/` — `link_dotfiles()` links every
  `.config/*` entry automatically, so no installer change is needed.
- A new **root-level** dotfile must be added to the `for f in ...` list in
  `link_dotfiles()` (`setup/lib.sh`), or it never gets deployed.
- Anything that leaves a file outside this repo needs a step in an installer —
  **and picking which one is the decision**: shared behaviour goes in
  `setup/lib.sh`, a `defaults write` or a `launchctl` bootstrap in `install.sh`,
  a `systemctl` or `fc-cache` call in `install-linux.sh`. Every step must be
  **idempotent**, guarded, and print via `info`/`success`/`warning`/`error`.
- A new package goes in `homebrew/Brewfile` *and* `arch/pkglist` (or
  `arch/aurlist`). The Arch lists were transcribed from the Brewfile and have
  never been checked against a live mirror; `install-linux.sh` validates every
  name against the sync database and reports the unknown ones rather than
  failing the transaction, so the first real run is what settles them.
- Removing a config: `link_dotfiles()` already sweeps dangling `~/.config`,
  `~/.claude/skills` and `~/.claude/agents` symlinks that point into this repo.
  Root-level retirements go in the "Retired links" list instead.

## Do not run `install.sh` to test a change

It asks for sudo, edits `/etc/pam.d/sudo_local`, runs `brew bundle`, and loads
LaunchAgents. Verify narrowly instead:

```sh
bash -n install.sh && bash -n install-linux.sh    # bash: parse both
shellcheck install.sh install-linux.sh setup/*.sh \
  .claude/hooks/notify.sh .claude/statusline.sh   # ...then lint every one
for f in .zshenv .zprofile .zshrc zsh/*.zsh zsh/extra/*.zsh zsh/os/*.zsh; do
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

`shellcheck` currently exits 1 on a clean tree: six SC2015 `info`s on the
deliberate `cmd && success || warning` lines — five in `install-linux.sh`, one
in `setup/lib.sh` (all are best-effort steps where the "C may run when A is
true" caveat is acceptable). Read the findings, don't chase the exit status, and
don't rewrite those lines into `if`/`else` just to silence it. `install.sh`
itself is now clean; the two it used to report moved into `setup/lib.sh` with
the code.

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
`LS_COLORS` isn't a zinit plugin. When you change one of those decisions, update
the comment that justified the old one. A change with no rationale attached does
not match this codebase.

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


# Coding Rules

Please follow all of the following coding rules.

- Make changed code explain its behavior through names and structure.
- Use comments only to explain reasons that code cannot express.
- Use vertical whitespace (blank lines) between logical steps, declaration groups, and completed control-flow blocks.
- Do not write minified code. Code should always be formatted to be read and maintained.
- Add correctly formatted PHPDoc, JSDoc, or respective comment-based type-hinting to every function you add or change.

# Compact instructions

When you are using compact, please focus on test output and code changes
