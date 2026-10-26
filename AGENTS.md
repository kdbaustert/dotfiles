# dotfiles

Personal macOS dotfiles, deployed by `install.sh`, which sources
`setup/lib.sh`. This is the repo contract for
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

The global `.claude/CLAUDE.md` lists the symlinks into `~/dotfiles` under
**Environment** (`~/.profile` links to `.zprofile`). **Edit the file in
`~/dotfiles`**, never the `$HOME` path. The one exception is `~/.hushlogin`,
which `install.sh` `touch`es because only its existence is read.

**Never run a tool that rewrites one of these files in place**; the change
lands in the tracked file without a sign. Known offenders:

- `iris setup` / `iris uninstall` rewrite the shell RC.
- `abbr add` / `abbr erase` rewrite `zsh/abbreviations` and drop its comments.
  Edit that file by hand.
- `git config --global` rewrites `.gitconfig` and can replace the symlink.
  `brew` does it too, adding a `[safe] directory` pair on each
  dubious-ownership hit. The extras are inert; collapse them to one pair per
  path with the recipe in the comment above the block.

## Layout

- Shared agent instructions and scripts: `.claude/`.
- Portable preferences: `.claude/settings.portable.json`, `.codex/settings.toml`.
  The shared installer merges these into live configs; do not symlink app state.

Before changing deployment, agents, skills, hooks, status lines or app settings,
read the matching subsection of **Layout** in `setup/REFERENCE.md`. Before
editing vendored skills, read its provenance and conflict rules: refresh them
from upstream and diff rather than editing them in place. Global style wins.
The Neovim and LunarVim configs stay independent and share only voltage.nvim.

## macOS only

This repo targets macOS on Apple Silicon. Linux support (`install-linux.sh`,
the Arch package lists, the systemd units, `$DOTFILES_OS`) was removed on
2026-10-26; don't add platform branches back without being asked. Code that
calls Apple tools, Homebrew or `~/Library` paths goes in
`zsh/os/macos-{env,interactive}.zsh`, and .zprofile and .zshrc source those
files by fixed path at points that matter. Read **zsh/os** in
`setup/REFERENCE.md` before moving either source line.

## Adding or changing config

Every symlink lives in `link_dotfiles()` in `setup/lib.sh`, not in
`install.sh`. That is the one place to change.

- A new tool config goes in `.config/<tool>/` — `link_dotfiles()` links every
  `.config/*` entry automatically, so no installer change is needed.
- A new **root-level** dotfile must be added to the `for f in ...` list in
  `link_dotfiles()` (`setup/lib.sh`), or it never gets deployed.
- Anything that leaves a file outside this repo needs a step in `install.sh`,
  or in `setup/lib.sh` when it is long enough to crowd the section list. A
  `defaults write` or a `launchctl` bootstrap goes in `install.sh`. Every step
  must be **idempotent**, guarded, and print via
  `info`/`success`/`warning`/`error`.
- A new package goes in `homebrew/Brewfile`.
- Removing a config: `link_dotfiles()` already sweeps dangling `~/.config`,
  `~/.claude/skills` and `~/.claude/agents` symlinks that point into this repo.
  Root-level retirements go in the "Retired links" list instead.

### Never hard-code a name

Nothing you add or change may name a specific user, home directory, machine
or account (`kenny`, `/Users/kenny`, a hostname). Resolve it when the file runs
(`$HOME`, `$USER`, `$(hostname -s)`) or, for a format with no variables, at
install time. **Never hard-code a name** in `setup/REFERENCE.md` has the recipe
for each format; read it before adding a plist, TOML, YAML or launchd label.

The only exceptions are files whose job is identity: the `[user]` block in
`.gitconfig`, `.config/git/allowed_signers` and the copyright line in
`LICENSE.MD`. Don't add another without writing why next to it. Point out a
leftover literal you find; don't fix it inside an unrelated change.

## Do not run `install.sh` to test a change

`install.sh` is not a test: it installs packages and change services and
system files. Test functions in isolation with temporary destinations.
Read **Do not run `install.sh` to test a change** in `setup/REFERENCE.md` before
verification, then run only the checks relevant to the edit. Parse shell files
individually, and lint changed scripts plus callers. ShellCheck has three known
SC2015 findings, two in `install.sh` and one in `setup/lib.sh`; inspect findings
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

Before staging anything, read **Generated vs. tracked** in `setup/REFERENCE.md`.
Some generated files here must never be committed and some must be.

## Colors

Every palette change starts at `themes/voltage.md`, which holds the canonical
hex values and lists every file that copies them. Update all of them together,
then re-run the `install.sh` cache steps for `bat` and fast-syntax-highlighting.

# Coding Rules

Please follow all of the following coding rules.

- Use comments only to explain reasons that code cannot express.
- Use vertical whitespace (blank lines) between logical steps, declaration groups, and completed control-flow blocks.
- Add correctly formatted PHPDoc, JSDoc, or respective comment-based type-hinting to every function you add or change.

# Compact instructions

When you are using compact, please focus on test output and code changes

## Non-negotiable rules

### Tests and evals — every time, no exceptions

- What you RUN follows the triage size. Never skip the local checks.
- Every behavior change ships its test in the same diff, and every bug fix a regression test that fails with the bug present. No "tests later". Only non-behavioral small changes (typo, copy, styling value) skip a new test.
- Evals are only for code that calls an LLM: it ships one with a pass threshold, run before ship, not on every commit.

  ### Tech choice — vanilla by default

- Simplest vanilla tech wins. No framework-of-the-month. No clever abstractions for hypothetical reuse.
- Do not recreate what already exists. Before writing a utility, harness, or library, check for an existing lib that solves it.
- Only when about to add a new dependency for a cross-cutting concern (eval harness, prompt library, vision utilities, observability, SEO, schema validation, etc.), search GitHub for top candidates. Don't run this survey for a change that adds no dependency. Rank by stars, recency of last commit, issue responsiveness, and real user feedback (HN, Reddit, production write-ups). Return the best option with reasoning, not a list. Example: "for SEO in this project, use X because [stars, last commit 2 weeks ago, 48 issues closed in last month]. Second choice Y. Rejected Z because [last commit 14 months ago]."
- If two options are equally viable, name the trade-off explicitly and ask Kenny.

### Check for skills

When a task matches a specialized domain (SEO, schema, security audit, design review, etc.), use the installed Claude Code skill. Don't reinvent what an installed skill already does well. Invoke via the Skill tool, not by re-implementing.

Before any critic pass (the medium task's one pass, or the large task's loop), read **Critic per work type** in `setup/REFERENCE.md` for how the critic attacks that kind of work.

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

Destructive commands need confirmation first, under *Ask before destructive or hard-to-reverse actions* in the global `.claude/CLAUDE.md`. On top of that:

- Never commit secrets, binaries, compiled output or model weights. If `.env` is touched, check `.gitignore` before any commit.
- A confirmed force push uses `git push --force-with-lease --force-if-includes`. `--force-with-lease` alone is defeated by the `git fetch` before a rebase and drops a teammate's commit silently. Never on a shared branch or `main`.
- When a pre-commit hook fails, fix the cause; never `--no-verify`.
- Before anything that touches production, say what you're about to do and wait.

How to talk to Kenny lives in the global `.claude/CLAUDE.md` (*Be direct*,
*Write like a person*) and `.claude/rules/human-writing.md`, which load in every
project. A third copy here was dropped on 2026-10-26 to cut startup tokens.
