# dotfiles

Personal macOS and Arch/Manjaro dotfiles, deployed by `install.sh` and
`install-linux.sh`. Both source `setup/lib.sh`. This is the repo contract for
Claude Code, Codex and any other agent that reads `AGENTS.md`;
`.claude/CLAUDE.md` is the separate global contract.

`setup/REFERENCE.md` holds deployment details and history. Read its matching
sections only when the task calls for them; do not import it into startup
context. Essential rules remain here.

`AGENTS.md` is the real file. `CLAUDE.md` is a relative symlink to it, because
Claude Code loads `CLAUDE.md` and Codex loads `AGENTS.md`. **Edit `AGENTS.md`.**
Anything that rewrites `CLAUDE.md` by replacing it (`sed -i`, `perl -i`) turns
the link into a copy that stops tracking. Keep this file under 32 KiB, Codex's
default `project_doc_max_bytes`; past that it gets cut off. Run
`setup/check-agents-md.sh` after editing it. **Agent instructions** in
`setup/REFERENCE.md` has the reasons.

Portable model and token preferences are merged automatically by the
installers.

## How to work (high-level mindset)

**This section is non-negotiable and must never be removed.**

The marginal cost of completeness is near zero with AI. Do the whole thing. Do it right. Do it with tests. Do it with documentation. Do it so well that Kenny is genuinely impressed — not politely satisfied, actually impressed. Never offer to "table this for later" when the permanent solve is within reach. Never leave a dangling thread when tying it off takes five more minutes. Never present a workaround when the real fix exists. The standard isn't "good enough" — it's "holy shit, that's done."

Search before building. Test before shipping. Ship the complete thing. When Kenny asks for something, the answer is the finished product, not a plan to build it.

You can outsource the typing. You cannot outsource the understanding. Before you call anything DONE you must be able to explain why the code is correct and exactly where it would break. Tests passing is not understanding. If you can't walk the failure modes out loud, you're not done, you're guessing.

## Task sizing — triage before spending tokens

**This section is non-negotiable and must never be removed.** It gates the tests rule, and the fan-out rule. "Do the whole thing" means the whole thing the task actually needs. A full-protocol run on a typo is not thoroughness, it is waste.

**Every task starts with a printed triage block, before any work.** Four lines:

```
Size: small | medium | large — why
Tests: local (which ones) | full suite — why
Agents: solo | fan-out (how many, on what) — why
Branch: <current branch> in <repo path>
```

This block is mandatory and verbose on purpose. Kenny reads it to see what mode was picked and to tune these rules over time. A wrong mode is only correctable if the choice is visible. Never skip it, never bury it mid-report. The Branch line is there so that with several sessions running at once, Kenny can tell at a glance which one is about to touch what.

**The sizes:**

- **small** — typo, copy change, color or styling value, config tweak, rename, any one-or-two-file mechanical edit with no behavior change. Solo, no fan-out, no critic sub-agent. Run only the checks that cover what was touched: the module's existing tests, lint, build. A non-behavioral change needs no new test.
- **medium** — localized behavior change or bug fix inside one service or module. Solo by default; fan out only if the work splits into truly independent units. Run the touched service's test suite, not the whole repo's. Bug fixes still ship the regression test. One cold critic pass.
- **large** — new feature, cross-service or contract change, architecture work, anything judgment-heavy (design, approach, UX). Full protocol: fan-out, harsh critic loop, full test + eval suites for every service touched.

**Deciding rules:**

- When torn between two sizes, pick the smaller one and say so in the triage block. Escalating mid-task is cheap; burning a large-protocol run on a small change is not.
- Escalate the moment the change turns out bigger than triaged (touches a contract, spreads across services, needs judgment). Print an updated triage block right then, with what changed the call.
- "Test what you touch" is the default. The full suite is for large changes and contract changes. The blast radius decides, not habit: if the diff cannot reach code outside the touched module, running that module's tests IS the complete verification.
- The final report restates what was actually run (which tests, which agents) so the triage call can be judged after the fact.

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

## Colors

Every palette change starts at `themes/voltage.md` — it holds the canonical hex
values and lists every file that transcribes them (ghostty, starship, fzf, vivid,
bat, btop, lsd, atuin, fsh, yazi, glow, `voltage.nvim`). Update the doc and all
consumers together; drift between two copies of the palette is the exact failure
that file exists to prevent. `bat` and fast-syntax-highlighting compile their
themes into caches and need the corresponding `install.sh` steps re-run.

# Coding Rules

Please follow all of the following coding rules.

- Use comments only to explain reasons that code cannot express.
- Use vertical whitespace (blank lines) between logical steps, declaration groups, and completed control-flow blocks.
- Add correctly formatted PHPDoc, JSDoc, or respective comment-based type-hinting to every function you add or change.

# Compact instructions

When you are using compact, please focus on test output and code changes

## Non-negotiable rules

### Tests and evals — every time, no exceptions

- Scope what you RUN by the triage size (see "Task sizing"): small and medium changes run only the tests covering the touched code; the full suite is for large and contract changes. State in the report which lane ran and why. Never run the whole repo's suite for a few-words diff, and never skip the local checks either.
- What you WRITE still follows the rules below. "No new test needed" applies only to non-behavioral small changes (typo, copy, styling value); every behavior change ships its test.
- Every feature ships with a test suite AND an eval suite, in the same commit. Not the next PR.
- Every bug fix ships with a test AND an eval that would have caught the bug. The regression test is the proof the bug is fixed. The eval is the proof the fix generalizes.
- "I'll add tests later" is banned. If the tests/evals aren't in the diff, the work isn't done.
- Two test lanes, different budgets:
  - **Gate tests** — deterministic, local, free, <2s. Run on every commit via pre-commit hook. Never flaky.
  - **Periodic evals** — paid (LLM calls), slower, quality-measuring. Run before ship and nightly. Allowed to be non-deterministic but must have a pass threshold.

  ### Tech choice — vanilla by default

- Simplest vanilla tech wins. No framework-of-the-month. No clever abstractions for hypothetical reuse.
- Do not recreate what already exists. Before writing a utility, harness, or library, check for an existing lib that solves it.
- For cross-cutting concerns (eval harness, prompt library, vision utilities, observability, SEO, schema validation, etc.) grep GitHub in parallel for top candidates. Rank by stars, recency of last commit, issue responsiveness, and real user feedback (HN, Reddit, production write-ups). Return the best option with reasoning, not a list. Example: "for SEO in this project, use X because [stars, last commit 2 weeks ago, 48 issues closed in last month]. Second choice Y. Rejected Z because [last commit 14 months ago]."
- If two options are equally viable, name the trade-off explicitly and ask Kenny.

### Check for skills

When a task matches a specialized domain (SEO, schema, security audit, design review, etc.), use the installed Claude Code skill. Don't reinvent what an installed skill already does well. Invoke via the Skill tool, not by re-implementing.

**The critic per work type** (the pattern is constant, the weapon changes):

- **Copy/parity:** real reference, blind side-by-side, visual and behavioral.
- **New feature:** rubric plus best-in-class analog; critic uses it cold like a first-time user.
- **Bug fix:** the reference is the repro. The critic is an attacker: re-break the fix, probe neighboring inputs, verify the regression test fails with the bug present.
- **Performance:** numeric budget stated before work starts; the critic reads only the numbers.
- **Docs:** critic reads cold and actually follows them; the first confusion is a FAIL.
- **Security/code quality:** adversarial reviewer trying to break it (inputs, races, edge cases).

**Solo (no fan-out) is the rule for:** small tasks, most medium tasks, conversational answers, and reading/investigation that fits in one context. Medium bug fixes still get the one cold critic pass from "Task sizing" (an attacker on the repro). When in doubt between medium and large, triage says pick medium; when a large task is in doubt about how to split, fan out.

## Completion status protocol

At the end of every task, report one of these, emoji included, since markdown has no text color and the circle is what makes the status readable at a glance:

- **🟢 DONE** — All steps completed. Evidence provided for every claim. Tests + evals in the diff as the triage size requires. Ready to merge.
- **🟡 DONE_WITH_CONCERNS** — Completed, but with issues Kenny should know about. List each concern with severity and a proposed follow-up.
- **🔴 BLOCKED** — Cannot proceed. State what's blocking and what was already tried.
- **🔵 NEEDS_CONTEXT** — Missing information required to continue. State exactly what's needed.

"Partially done" is not a status. Either the feature ships (DONE) or it doesn't (BLOCKED / NEEDS_CONTEXT). Honesty about incompleteness beats pretending.

## Background jobs and backfills

Before starting any long-running background job (batch, migration, backfill, scrape), load the `backfill-protocol` skill and follow it. A job that modifies data must not start until its snapshot exists.

## Safety

- Never commit secrets. If `.env` is touched, verify `.gitignore` before any commit.
- Never run `rm -rf`, `git reset --hard`, `git push --force`, `DROP TABLE`, `kubectl delete`, or similar destructive ops without explicit confirmation. When a force push is confirmed, use `git push --force-with-lease --force-if-includes`. Both flags are required: `--force-with-lease` on its own is defeated by the `git fetch` that precedes a rebase, and will destroy a teammate's commit without a word. Never on a shared branch, never on `main`.
- Never skip pre-commit hooks with `--no-verify`. If a hook fails, fix the underlying issue.
- Never commit binaries, compiled outputs, or model weights to the repo. Use Git LFS or cloud storage with a pointer.
- Before any action that touches production, state what you're about to do, wait for confirmation.

## How Kenny wants to be talked to

- Direct. Short. Concrete. No preamble.
- Specific file names, function names, line numbers. Not "there's an issue in the classifier" — it's `food_vision/classifier.py:47`.
- No em dashes. No AI vocabulary (delve, crucial, robust, comprehensive, nuanced, multifaceted, furthermore, moreover, pivotal, landscape, tapestry, underscore, foster, showcase, intricate, vibrant, fundamental, significant, interplay).
- No banned phrases: "here's the kicker", "here's the thing", "plot twist", "let me break this down", "the bottom line", "make no mistake".
- If something is broken, say so plainly.
- End responses with the next action, not a recap of what was just done.

When Kenny asks for something, the answer is the finished product — not a plan. Tests included. Evals included. Docs included.

## ALWAYS START WITH THESE COMMANDS FOR COMMON TASKS

**Task: "List/summarize all files and directories"**

```bash
fd . -t f           # Lists ALL files recursively (FASTEST)
# OR
rg --files          # Lists files (respects .gitignore)
```

**Task: "Search for content in files"**

```bash
rg "search_term"    # Search everywhere (FASTEST)
```

**Task: "Find files by name"**

```bash
fd "filename"       # Find by name pattern (FASTEST)
```

### Directory/File Exploration

```bash
# FIRST CHOICE - List all files/dirs recursively:
fd . -t f           # All files (fastest)
fd . -t d           # All directories
rg --files          # All files (respects .gitignore)

# For current directory only:
ls -la              # OK for single directory view
```

### BANNED - Never Use These Slow Tools

* ❌ `tree` - NOT INSTALLED, use `fd` instead
* ❌ `find` - use `fd` or `rg --files`
* ❌ `grep` or `grep -r` - use `rg` instead
* ❌ `ls -R` - use `rg --files` or `fd`
* ❌ `cat file | grep` - use `rg pattern file`

### Use These Faster Tools Instead

```bash
# ripgrep (rg) - content search
rg "search_term"                # Search in all files
rg -i "case_insensitive"        # Case-insensitive
rg "pattern" -t py              # Only Python files
rg "pattern" -g "*.md"          # Only Markdown
rg -1 "pattern"                 # Filenames with matches
rg -c "pattern"                 # Count matches per file
rg -n "pattern"                 # Show line numbers
rg -A 3 -B 3 "error"            # Context lines
rg " (TODO| FIXME | HACK)"      # Multiple patterns

# ripgrep (rg) - file listing
rg --files                      # List files (respects •gitignore)
rg --files | rg "pattern"       # Find files by name
rg --files -t md                # Only Markdown files

# fd - file finding
fd -e js                        # All •js files (fast find)
fd -x command {}                # Exec per-file
fd -e md -x ls -la {}           # Example with ls

# jq - JSON processing
jq. data.json                   # Pretty-print
jq -r .name file.json           # Extract field
jq '.id = 0' x.json             # Modify field
```

### Search Strategy

1. Start broad, then narrow: `rg "partial" | rg "specific"`
2. Filter by type early: `rg -t python "def function_name"`
3. Batch patterns: `rg "(pattern1|pattern2|pattern3)"`
4. Limit scope: `rg "pattern" src/`

### INSTANT DECISION TREE

```
User asks to "list/show/summarize/explore files"?
  → USE: fd . -t f  (fastest, shows all files)
  → OR: rg --files  (respects .gitignore)

User asks to "search/grep/find text content"?
  → USE: rg "pattern"  (NOT grep!)

User asks to "find file/directory by name"?
  → USE: fd "name"  (NOT find!)

User asks for "directory structure/tree"?
  → USE: fd . -t d  (directories) + fd . -t f  (files)
  → NEVER: tree (not installed!)

Need just current directory?
  → USE: ls -la  (OK for single dir)
```