# dotfiles

Personal macOS and Arch/Manjaro dotfiles, deployed by `install.sh` and
`install-linux.sh`. Both source `setup/lib.sh`. This is the repo contract for
Claude Code and Codex; `.claude/CLAUDE.md` is the separate global contract.

`setup/REFERENCE.md` holds deployment details and history. Read its matching
sections only when the task calls for them; do not import it into startup
context. Essential rules remain here.

Codex discovers this file through these root keys in its untracked config,
placed above the first `[table]`:

```toml
project_doc_fallback_filenames = ["CLAUDE.md"]
project_doc_max_bytes = 65536
```

Those discovery keys remain a manual setup step. Portable model and token
preferences are merged automatically by the installers.

## The one rule that breaks everything else

`~/.zshrc`, `~/.zprofile`, `~/.profile` (a second link to `.zprofile`),
`~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`, `~/.prettierrc`,
`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.override.md` (a second link to it),
`~/.claude/REFERENCE.md`, `~/.claude/hooks/notify.sh`,
`~/.claude/hooks/search-excludes.sh`, `~/.claude/hooks/resume-after-limit.sh`, `~/.claude/statusline.sh`, every `~/.claude/skills/<skill>` directory, every
`~/.claude/rules/<rule>.md` file and every
`~/.config/<tool>` entry are symlinks into this repo. **Edit the file in `~/dotfiles`.** Never write to the
`$HOME` path. One exception: `~/.hushlogin`, which `install.sh` `touch`es
rather than links because only its existence is ever read.

There used to be a second — `~/Library/Fonts/HackNerdFontColor-Regular.ttf`, a
COLR/CPAL build of Hack copied rather than linked because CoreText does not
register a symlinked font. It existed to tint the tab-icon glyphs
`zsh/extra/tabtitle.zsh` wrote into Ghostty's tab titles, and went when that
mechanism did. A stale copy may still sit in `~/Library/Fonts` on a machine
that installed it; nothing reads it now, and removing it is by hand.

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

- Shell: `.zshrc`, `.zprofile`, `.zshenv`, `zsh/`.
- Tool configs: `.config/`; packages: `homebrew/Brewfile`, `arch/`.
- Shared installer functions: `setup/lib.sh`; OS entry points: `install.sh`
  and `install-linux.sh`.
- Shared agent instructions and scripts: `.claude/`.
- Portable preferences: `.claude/settings.portable.json`, `.codex/settings.toml`.
  The shared installer merges these into live configs; do not symlink app state.

Before changing deployment, agents, skills, hooks, status lines or app settings,
read the matching subsection of **Layout** in `setup/REFERENCE.md`. Before
editing vendored skills, read its provenance and conflict rules: refresh them
from upstream and diff rather than editing them in place. Global style wins.
The Neovim and LunarVim configs stay independent and share only voltage.nvim.

## macOS and Linux

Deploy to both macOS and Arch/Manjaro. Keep one tracked source per setting.
Shared installer behavior belongs in `setup/lib.sh`; OS-specific behavior belongs
in its installer. Prefer portable values, then inline `$DOTFILES_OS` branches
for paired values, and `zsh/os/<os>-{env,interactive}.zsh` for one-platform code.
Read **macOS and Linux** in `setup/REFERENCE.md` before changing OS dispatch or
terminal deployment; source order and the Ghostty exception are intentional.

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

### Never hard-code a name

Nothing you add or change here may name a specific user, home directory,
machine or account. No `kenny`, no `/Users/kenny`, no `/home/kenny`, no
`Kenny's MacBook Pro`. Resolve it when the file runs instead. This repo deploys to more than one
machine, the macOS and Linux home roots are different, and a new machine might
use a different account name. A literal works on the machine it was written on
and breaks without warning everywhere else. That is the same silent failure the
installer loops exist to prevent.

Use whatever dynamic form the file format supports:

- Shell: `$HOME`, `$USER` / `$(id -un)`, `$(hostname -s)`, `$DOTFILES_OS`, and
  `~` wherever the shell expands it.
- systemd units: `%h`, `%u`. `systemd/claude-usage-refresh.service` is the
  model to follow.
- A plist, TOML or YAML with no variables of its own: generate it or substitute
  into it from the installer at deploy time, which is how the hosts-refresh
  LaunchDaemon is built. If the tool reads a path relative to `$HOME` or
  `$XDG_CONFIG_HOME` by itself, drop the path and let it.
- Identifiers such as launchd labels come from a variable derived at install
  time. Don't embed a personal domain or handle.

The only exceptions are files whose whole job is to say who someone is: the
`[user]` block in `.gitconfig`, `.config/git/allowed_signers`, and the
copyright line in `LICENSE.MD`. Git and SSH read those as literals and cannot
work them out. Don't add another exception without writing down why next to
it. If you come across a leftover literal while working on something else,
point it out; don't fix it silently as part of an unrelated change.

## Do not run `install.sh` to test a change

Neither full installer is a test: they install packages and change services and
system files. Test functions in isolation with temporary destinations.
Read **Do not run `install.sh` to test a change** in `setup/REFERENCE.md` before
verification, then run only the checks relevant to the edit. Parse shell files
individually, and lint changed scripts plus callers. ShellCheck has eight known
SC2015 findings across the installers and shared library; inspect findings
rather than treating its exit status as proof of a regression.

Shell startup is budgeted: keep new work off the critical path, use the existing
`zcache` helper for tool initialization and measure any startup change.

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
(built from our `voltage.ini`; it's what themes a fresh machine) and both
`lazy-lock.json` files (they pin the plugin sets for `:Lazy restore`).

`fonts/build-tab-icons.py` and its two committed outputs used to be the third
case here. The whole tab-icon mechanism is gone, so the exception it needed
went with it.

## Colors

Every palette change starts at `themes/voltage.md` — it holds the canonical hex
values and lists every file that transcribes them (ghostty, starship, fzf, vivid,
bat, btop, lsd, atuin, fsh, yazi, glow, `voltage.nvim`). Update the doc and all
consumers together; drift between two copies of the palette is the exact failure
that file exists to prevent. `bat` and fast-syntax-highlighting compile their
themes into caches and need the corresponding `install.sh` steps re-run.

# Coding Rules

Please follow all of the following coding rules.

- Make changed code explain its behavior through names and structure.
- Use comments only to explain reasons that code cannot express.
- Use vertical whitespace (blank lines) between logical steps, declaration groups, and completed control-flow blocks.
- Do not write minified code. Code should always be formatted to be read and maintained.
- Add correctly formatted PHPDoc, JSDoc, or respective comment-based type-hinting to every function you add or change.

# Compact instructions

When you are using compact, please focus on test output and code changes
