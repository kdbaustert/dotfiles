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

## How to work (high-level mindset)

**This section is non-negotiable and must never be removed.**

The marginal cost of completeness is near zero with AI. Do the whole thing. Do it right. Do it with tests. Do it with documentation. Do it so well that Kenny is genuinely impressed — not politely satisfied, actually impressed. Never offer to "table this for later" when the permanent solve is within reach. Never leave a dangling thread when tying it off takes five more minutes. Never present a workaround when the real fix exists. The standard isn't "good enough" — it's "holy shit, that's done."

Search before building. Test before shipping. Ship the complete thing. When Kenny asks for something, the answer is the finished product, not a plan to build it.

You can outsource the typing. You cannot outsource the understanding. Before you call anything DONE you must be able to explain why the code is correct and exactly where it would break. Tests passing is not understanding. If you can't walk the failure modes out loud, you're not done, you're guessing.

## Task sizing — triage before spending tokens

**This section is non-negotiable and must never be removed.** It sets how much testing, fan-out and critique a task gets. "Do the whole thing" means what the task needs; a full protocol on a typo is waste.

**Every task starts with this triage block, printed before any work.** Kenny reads it to check the mode and tune these rules, and the Branch line tells parallel sessions apart. Never skip it or bury it.

```
Size: small | medium | large — why
Tests: local (which ones) | full suite — why
Agents: solo | fan-out (how many, on what) — why
Branch: <current branch> in <repo path>
```

- **small**: typo, copy, styling value, config tweak, rename, or a one-or-two-file mechanical edit with no behavior change. Solo, no critic. Run the checks covering what was touched; no new test.
- **medium**: a behavior change or bug fix inside one module. Solo unless the work splits into independent units. Run that module's tests, ship the regression test, one cold critic pass.
- **large**: new feature, cross-service or contract change, architecture, anything judgment-heavy. Fan out, harsh critic loop, full test and eval suites for every service touched.

When torn, pick the smaller size and say so. Escalate the moment the work proves bigger, with a new triage block saying why. Test what you touch: if the diff can't reach outside the module, its tests are the complete verification. The final report restates which tests and agents actually ran.

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

- Portable preferences: `.claude/settings.portable.json`, `.codex/settings.toml`.
  The shared installer merges these into live configs; do not symlink app state.

Before changing deployment, agents, skills, hooks, status lines or app settings,
read the matching subsection of **Layout** in `setup/REFERENCE.md`. Vendored
skills are refreshed from upstream and diffed, never edited in place. Global
style wins.
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
`install.sh`.

- A new tool config goes in `.config/<tool>/`, which `link_dotfiles()` links
  automatically. A new **root-level** dotfile must be added to its
  `for f in ...` list, or it never deploys.
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

It installs packages and changes services and system files. Test functions in
isolation with temporary destinations; the section of the same name in
`setup/REFERENCE.md` has the parse and lint commands. ShellCheck's three SC2015
notes (two in `install.sh`, one in `setup/lib.sh`) are known, so read findings
rather than trusting its exit status.

Shell startup is budgeted: keep new work off the critical path, use the existing
`zcache` helper for tool initialization and measure any startup change.

## Style

`.editorconfig` governs formatting. Shell scripts in `setup/` and `install.sh`
declare a **bash** shebang and use bash arrays — they are run directly, never via
`sh`.

**Comments here explain *why*, and are expected to be long.** Rejected
alternatives are documented inline; when you change one of those decisions,
update the comment that justified it. A change with no rationale attached
doesn't match this codebase.

## Generated vs. tracked

Before staging anything, read **Generated vs. tracked** in `setup/REFERENCE.md`.
Some generated files here must never be committed and some must be.

## Colors

Every palette change starts at `themes/voltage.md`, which holds the canonical
hex values and lists every file that copies them. Update all of them together,
then re-run the `install.sh` cache steps for `bat` and fast-syntax-highlighting.

# Coding Rules

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
- Before adding a dependency for a cross-cutting concern (eval harness, observability, SEO, schema validation), survey GitHub by stars, last commit, issue response and real user reports, and recommend one with reasons. Skip the survey when no dependency is added.
- If two options are equally viable, name the trade-off explicitly and ask Kenny.

### Check for skills

When a task matches an installed skill's domain (SEO, schema, security audit, design review), use the skill rather than re-implementing it. Before any critic pass, read **Critic per work type** in `setup/REFERENCE.md`.

## Completion status protocol

End every task with one of these, emoji included; markdown has no color, so the circle is the signal.

- **🟢 DONE**: every step done, evidence for each claim, tests and evals as the triage size requires.
- **🟡 DONE_WITH_CONCERNS**: done, plus each concern with its severity and a follow-up.
- **🔴 BLOCKED**: what blocks it and what was tried.
- **🔵 NEEDS_CONTEXT**: exactly what's missing.

"Partially done" is not a status. Either it ships (DONE) or it doesn't (BLOCKED / NEEDS_CONTEXT).

## Background jobs and backfills

Load the `backfill-protocol` skill before any long-running batch, migration, backfill or scrape. A job that modifies data waits until its snapshot exists.

## Safety

Destructive commands need confirmation first, under *Ask before destructive or hard-to-reverse actions* in the global `.claude/CLAUDE.md`. On top of that:

- Never commit secrets, binaries, compiled output or model weights. If `.env` is touched, check `.gitignore` before any commit.
- A confirmed force push uses `git push --force-with-lease --force-if-includes` (**Git** in `.claude/REFERENCE.md` says why), never on a shared branch or `main`.
- When a pre-commit hook fails, fix the cause; never `--no-verify`.
- Before anything that touches production, say what you're about to do and wait.
