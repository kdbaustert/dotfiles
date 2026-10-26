# Reference for the global instructions

Claude Code loads `CLAUDE.md` into every session and never loads this file on
its own. `CLAUDE.md` keeps the rules; this file keeps the measurements, history
and reasons behind them, under the same headings, so the per-session cost is the
rules alone. `CLAUDE.md` says when to read a section here. When you change a rule
there, update its reasoning here in the same edit.

Most of what follows is the original wording from before the split.

## Precedence

Claude Code loads this file *and* the project's `CLAUDE.md`, concatenated in that
order, rather than choosing between them. There is no setting that suppresses the
global file for a single project — verified against 2.1.235 — so the precedence
rule in `CLAUDE.md` is the only mechanism there is. A project file that overrides
a rule should name the rule it overrides, so the override still reads as
deliberate after the global file changes.

Claude Code had no AGENTS.md discovery path at either scope when measured on
2.1.231, so the tooling contract lives in `CLAUDE.md` rather than in a sibling
one pulled in by an `@AGENTS.md` import, which went missing silently rather than
erroring. 2.1.310 added a builtin `cc-plugin-agents-md` plugin that loads a
project's `AGENTS.md` where it has no `CLAUDE.md`. User scope on 2.1.310 hasn't
been tested.

This file is not an `@import` for the same kind of reason in reverse: an import
is loaded eagerly, which would put every line here back into every session and
undo the split.

## Environment

**Nix is installed beside Homebrew, and each owns a different job.** Nix
(upstream, multi-user daemon, put there by `install.sh`) is for per-project
environments — `nix-shell`, `nix develop` — and nothing global. Homebrew owns the
machine: casks, fonts, and every global CLI tool. Never `nix profile install` or
`nix-env -i` a tool the Brewfile already has — ripgrep, fd, jq, bat, eza, fzf,
zoxide, starship, atuin, git, delta, lazygit, neovim, node and python all exist in
both, and a second copy only drifts. The shell hook is sourced from `.zprofile`
*before* the path array, so `/opt/homebrew/bin` outranks `~/.nix-profile/bin`
(measured: positions 6 and 11 in a login shell), and `/etc/zshrc` is deliberately
left unedited. `.zprofile` is login-only, so a Bash tool call may not see `nix` at
all — the session that wrote this did not. `command -v nix-shell` is the check,
and sourcing `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` first is
the fix; don't splice `/nix/...` into a tool call's PATH by hand. Flakes are on via
`.config/nix/nix.conf`, and `direnv` (Homebrew, with nix-direnv fetched by
`.config/direnv/direnvrc`) loads a project's dev shell on `cd` — ghostty, rio and
kennybdev each carry an `.envrc`. That is a prompt hook, so a tool call never gets
the shell; run `nix develop -c <cmd>` from the project instead.

There is no Python version manager because `pyenv` was removed: it managed zero
versions.

**`node` is version-skewed by shell type.** `nvm` is lazy-loaded
(`NVM_LAZY_LOAD` in `.zprofile`, turbo-deferred in `zsh/zinit.zsh`) and is a shim
*function*, not a binary. It manages one version, v26.5.0. Non-interactive shells
and scripts — which is what a Bash tool call is — never load the plugin and get
Homebrew's `/opt/homebrew/bin/node`, v26.7.0 when measured. An interactive shell
gets the shim and v26.5.0. So a version you observe through a tool call is not the
version I get at a prompt; `whence -w node` in a real interactive shell is the
only honest check, not `zsh -i -c`, which exits before turbo fires.

GNU `coreutils`, `grep` and `gnu-sed` are installed but `gnubin` is deliberately
off `PATH`, so the defaults stay BSD. `gdircolors` is the other g-prefixed binary
worth knowing. There is no `gfind` because `findutils` is not installed.

Interactive aliases reaching tool calls is a hazard, not a convenience: `tree` is
not installed as a binary and resolves to the `llt` alias.

## The gotcha that actually bites

`fd`'s global ignore lives at `.config/fd/ignore`, deployed to
`~/.config/fd/ignore` and read automatically with no env var wiring it up. It
excludes `.git/` and `.DS_Store` and nothing else — that is signal-to-noise, not
speed: `--hidden` was making CTRL-T list 501 files in `~/dotfiles` of which 415
were `.git/` internals. `node_modules/`, `vendor/` and `dist/` are deliberately
*not* in it, so the advice about passing flags still holds for `dist/`.

Claude is told never to search `node_modules/`, `vendor/`, `build/`, `out/`,
`public/`, `storage/`, `logs/` or `tmp/` at all, and that rule lives in
`CLAUDE.md` rather than in this ignore file or an rg config. Adding them here
would also hide them from CTRL-T and every interactive `fd`, where looking inside
a dependency or a log is sometimes the point. And `-I`, which the flag advice
tells Claude to reach for, bypasses this file anyway, so the exclusion has to
travel with the command as one brace glob, `-E '{node_modules,vendor,...}'`. `rg
-g` and `fd -E` both expand the braces (checked with rg and fd on a scratch
tree), so one flag covers all eight.

`public/` is the risky entry. In a framework app it is build output, but a plain
PHP project can keep hand-written entry points there. The exception clause in
the rule covers a task that is about one of these folders, but a broad search
for a symbol will now miss a match in `public/`. kennybdev's `build/` is the
same trap: it holds hand-written scripts (`npm run og` runs
`build/og-render.js`).

The rule is short in `CLAUDE.md` because that file loads into every session;
the reasons for it are here. One hit in any of the eight folders buries the
results that matter, and `.gitignore` alone doesn't keep them out: not every
repo ignores them, and `-uu`, `-I` or a path passed straight to the search lets
them back in. Hence naming them on the command, and the hook as a backstop.

`.claude/hooks/search-excludes.sh` is that backstop, a PreToolUse hook on Bash.
It looks for an `rg` or `fd` command widened past the ignore files (`-u` in any
flag cluster, `--no-ignore*`, `--unrestricted`, or `fd -I`) and rejects it
with exit 2 if the command doesn't name all eight folders. Exit 2 hands the
message back to Claude, which reruns the search with the glob. A command whose
search path starts inside one of the folders passes, since that is the
exception the rule allows. It is a string check, not a shell parser: a widened
search hidden behind a variable or an alias gets through. It stays out of the
plain `rg`/`fd` case on purpose, because `.gitignore` covers that one in most
repos and blocking every search would cost more turns than it saves.

`--max-columns=200 --max-columns-preview`: one match in a minified bundle or a
SQL dump can be a single line tens of kilobytes long, and all of it lands in
the context. Checked on ripgrep 15.2.0: a 10,000-character matching line came
back as about 230 characters ending in `[... omitted end of long line]`. The
preview keeps the start of the line, so a match deep in it is cut off; `-o`
with a bounded pattern printed just the match and its 40 characters either
side (89 bytes for the same line).

A project's `.ignore` is the per-repo half. `rg` and `fd` read it by default,
like `.gitignore`, but it isn't git's, so it can hide things a repo tracks on
purpose (a committed minified bundle, a fixtures dump) from searches without
untracking them. `-uu` and `-I` bypass it, which is why the global eight still
travel on the command.

## How I want you to work

**`CLAUDE-REFERENCE.md`.** Claude Code auto-loads `CLAUDE.md` and nothing else,
so a repo that splits its mandatory rules from its architecture reference —
`cnc-claims` does, and the reference is where the framework's real behaviour is
written down — hands you only half of what it wrote for you, and withholds
exactly the half that stops you guessing at code you have not read. Treat it as
loaded context, not as a file to skim if a search happens to surface it. This is
*investigate first* aimed at documentation the harness will not hand you.

**Find the smallest change that works.** *Scope to the request* bounds what you
work on; this one bounds how much you touch to do it. Renaming something the task
didn't require, reformatting lines you only read, moving code to where it
'should' live, introducing config for a single call site and "while I'm here"
fixes are all the same failure: they bury the three lines that matter in a diff
nobody can review, and every one of them is a change I have to test. This is
*fight for the obvious solution* applied to the edit rather than the design. The
escape hatch matters: if the minimal change only papers over a real defect, say
so and let me decide — widening scope on your own is the thing to avoid, not
telling me the narrow fix is wrong.

## Code style

Swift is the one language here that does not take the 2-space default (measured:
the Swift projects here are 4 throughout).

Swift language modes: one package here is `.v6` because a threading mistake in
it stalls the event tap and the system answers by killing the app; another is
`.v5` on purpose because its AppKit panels hand state across callbacks that
strict concurrency cannot prove safe, and main-thread confinement already covers
it. Both reasons sit next to the setting; migrating one because the newer mode is
newer discards an argument I already had.

### Task rules

Follow the repo's existing style first. Absent a repo convention:

- 2-space indent, LF line endings, UTF-8, final newline, no trailing whitespace. CSS/SCSS use tabs (4).
- JS/TS: single quotes, no semicolons, 80 cols, `es5` trailing commas, arrow parens omitted for single args — i.e. run Prettier with `~/.prettierrc`.
- PHP: 120 cols, double quotes, no trailing commas, PHP 8.1 target.
- Swift: 4-space indent, 100 columns, standard Swift API design guidelines. `XCTest` unless the repo already imports `Testing`. No third-party formatter unless the repo ships one.
- Swift packages: `swift-tools-version: 6.0`, `platforms: [.macOS(.v14)]`, and an explicit `swiftLanguageMode` with a comment that says why that mode. Then leave it alone; don't migrate a package because a newer mode exists.

Regardless of language: small, focused functions; early returns rather than
nested conditionals; and no comment or docstring that only restates the code. A
repo that documents its *reasoning* in comments (`~/dotfiles` does) overrides that
last one, as repo convention always does.

Name each function for what it actually does, as closely as one name can say
it. A reader should be able to guess the body from the name and be right,
side effects included: a `getClaim()` that also marks the claim as read is
`fetchClaimAndMarkRead()`, and `handleData()` or `process()` says nothing at
all. When an edit changes what a function does, rename it in the same edit. If
no honest name fits without two "and"s, the function is doing too much. This
covers functions you add or change. A misleading name you only read gets
mentioned, not renamed, under *find the smallest change that works*.

## Tests

Model-written tests have tells just as model-written prose does, and a reviewer
who spots them stops trusting that the suite checks anything. That is the reason
for matching the tests already in the repo so closely.

A fixed sleep in a browser test (`cy.wait(5000)`, `$browser->pause(2000)`) is
either longer than it needs to be, which slows the suite, or shorter, which makes
it flaky. A CSS path copied out of devtools breaks the next time someone moves
the layout.

### Task rules

Write tests the way a developer on the team would. Read the tests already in the
repo before adding one, and match their framework, file layout, naming, fixtures
and helpers. This holds for PHPUnit, Laravel Dusk, Jest, Vitest and Cypress alike.
Absent a repo convention:

- **Name the behaviour plainly.** `rejects a claim with no policy number`, or
  `test_rounds_partial_hours_down`. Not `should successfully and correctly
  handle the case where...`. No comment above the test repeating its name.
- **No scaffolding comments.** No `// Arrange` / `// Act` / `// Assert` banners
  and no comment restating an assertion. A comment belongs in a test when it
  explains why an odd input or value was chosen.
- **Test what the code does, not how it does it.** Assert on what a caller could
  see: return values, output, saved state. Mocking the unit under test, or
  asserting only that a mock received the arguments you just handed it, proves
  nothing. Mock at the boundary (network, clock, filesystem, a third-party API)
  and leave the rest real.
- **Write the tests the change needs, not as many as possible.** One test per
  behaviour that could break, plus the edge cases the code actually has. No
  tests for trivial getters, no five near-copies where a data provider or table
  would do, and no `toBeDefined()` warm-up before the assertion that matters.
- **Assert exact values.** `toBe(42)`, `assertSame(42, $total)` and the full
  expected string, not `toBeTruthy()`, `assertNotEmpty()` or "returns an
  array". A loose assertion passes when the code is wrong.
- **In browser tests, wait for something and select by a test hook.** No fixed
  sleeps. Wait on what the user would see: `waitFor('@save')` or
  `waitForText()` in Dusk, and in Cypress let `cy.get()` retry or
  `cy.wait('@alias')` on an intercepted request. Select by a test attribute
  (`dusk="save"`, read as `@save`, or `data-cy="save"`), not a CSS path copied
  out of devtools. If the element has no hook, add one to the markup.
- **Keep setup in the test.** Pull it into a helper or factory once several
  tests share it. A builder class for a single test is the single-use
  abstraction *scope to the request* already rules out.
- **Never bend a test until it passes.** When one fails, either the code or the
  expectation is wrong, and finding out which is the job. Don't loosen the
  assertion, wrap it in a `try`, skip it, or change the expected value to
  whatever the code returns now without telling me.

## Linters and formatters

The shell and the editor run the same binaries on purpose — Neovim's Mason
provides language servers only. Prettier is a pnpm global in `~/Library/pnpm/bin`.

Swift has none of that installed. `swift format` (6.3.0) ships inside Xcode's
toolchain, so it is first-party and the *Code style* rule does not forbid it —
but its default indent is **2 spaces** and both Swift repos here are 4, so a bare
`swift format -i` reindents the whole tree. Both repos are already internally
consistent, so the diff would be reindentation burying whatever actually
changed. `swiftlint` is not in the Brewfile either.

`./build.sh --install` puts the release bundle in `/Applications` so what I run
is what you just changed. The installer quits the app, deletes the installed
bundle, copies the new one in and relaunches it, so the app disappearing for a
second is the install working rather than a crash. One repo here uses a different
build tool entirely.

### Task rules

Installed as real binaries: `shellcheck`, `shfmt`, `stylua` and `php-cs-fixer`
from Homebrew, plus Prettier as a pnpm global reading `~/.prettierrc`. Prefer a
repo's own pinned tooling when it ships one.

Swift: `swift format` ships with Xcode but defaults to 2 spaces, so run it only
with a config pinning `indentation.spaces: 4`, and prefer not to run it at all.
`swiftlint` is not installed; a repo that asks for it needs
`brew install swiftlint` first, so say so rather than skipping the lint step.

Verify shell edits without executing them: `bash -n` / `zsh -n` to parse,
`shellcheck` to lint.

Swift work is not finished at a clean compile. Once the change is complete (not
per edit), run `./build.sh --install`, which builds the release bundle and
installs it to `/Applications`. The running app quits and relaunches during the
install; that is expected. A repo with its own build script still wins.

## Git

Both remotes sign, each as its own identity: GitHub as `kenny@kennyb.dev`,
Bitbucket as the work identity via `~/.gitconfig-work` (a plain file in `$HOME`,
deliberately not in this repo), pulled in by `.gitconfig`'s
`includeIf hasconfig:remote.*.url`. Separate signing keys and separate
allowed-signers files — which is why `.config/git/allowed_signers` lists only the
personal key while the work one stays untracked at `~/.gitconfig-work-signers`.

The switch keys off the remote. Measured: a fresh `git init` reports
`kenny@kennyb.dev`, and both identity and key flip the moment the Bitbucket
remote is added. A first commit made before the remote lands under my personal
name, signed with a key the work account cannot attribute.

`attribution.commit` and `attribution.pr` are set to `""` in
`~/.claude/settings.json` to strip co-author trailers, but that file is untracked,
so the rule lives in `CLAUDE.md` too.

`develop` and `staging` are integration branches carrying everyone's in-flight
work, so merging one into a feature branch pulls other people's commits into my
history: the diff stops being reviewable, the *audit only my own changes* rule has
to work around it, and unpicking it afterwards costs far more than the merge
saved. Rebasing onto the branch it was cut from is usually the answer to a branch
that has fallen behind, but that is my call.

`delta` is invoked explicitly by the fzf-tab previews in `.zshrc`, which is why it
is not git's pager.

### Task rules

- Commits are SSH-signed through 1Password's `op-ssh-sign`, and the identity follows the remote: GitHub signs as the personal identity, Bitbucket as the work one from `~/.gitconfig-work`. A verification failure in a work repo is usually the signers file. A repo with **no remote yet** signs as personal, so add the Bitbucket remote before the first commit in a work repo.
- Don't disable either half: no `-c commit.gpgsign=false` to get past a signing prompt — tell me instead — and no per-repo `user.email` or `user.signingkey` set by hand.
- Never commit, push, or create a PR unless I ask.
- **No co-author trailers.** Commit messages end at the last line of prose — no
  `Co-Authored-By:`, no "Generated with Claude Code" in a PR body, no attribution
  footer of any kind. This overrides the harness default, which appends one.
- **Write commit messages the way a developer on the team would.** Run
  `git log --oneline -20` first and match the repo's tone and length. The subject
  is imperative ("Fix", "Add", "Drop"), under about 60 characters, with no
  trailing period and no `feat:`/`fix:` prefix unless the history already uses
  them. Plenty of commits need nothing more. When the reason isn't obvious from
  the diff, add a body wrapped at 72 columns that says why: the problem, the
  option you passed on, anything you didn't get to test. A one-line fix gets one
  line. Don't walk through the diff file by file. Leave out markdown headings,
  bold, emoji, "Summary" or "Changes" sections, and bullet lists of touched
  files. Don't open with "This commit" or end on a line that repeats the
  subject.
- **Never create a branch.** Commit on whatever branch I'm already on, including
  the default branch; this overrides the harness default of branching first on
  `main`/`master`. If a commit really shouldn't land on the current branch, say
  so and let me decide.
- **Never merge `develop` or `staging` into another branch.** They carry
  everyone's in-flight work, so a merge pulls other people's commits into my
  history. That holds for every target, including a merge that would only
  fast-forward. If a branch has fallen behind, say so and let me decide how to
  catch it up.
- Work repos use Bitbucket Pipelines (`bitbucket-pipelines.yml`), not GitHub Actions — check the right CI config.
- `delta` is **not** git's pager here, so `git diff` and `git show` emit plain output. Add `--no-pager` anyway when piping a command whose pager behaviour you have not checked.

## Audits and Jira comments

A branch picks up other people's commits by merge or rebase from the base branch
and, on a shared branch, by their own work, and a `git diff base...HEAD` shows all
of it without distinguishing. Reviewing a colleague's code back to them under my
name is worse than a thin audit.

Whoever reads an audit, and especially whoever reads it as a Jira comment, is a
claims handler, a tester or a manager. A change you skip because it is mechanical
is a change nobody knows to retest.

The Jira byline goes because the audit goes up under my name as my review, and
labelling it machine output invites the reader to treat it as unvetted. Same
instinct as the co-author rule.

`addCommentToJiraIssue`'s own schema says the `contentFormat` default *varies by
tool when omitted*, so leaving it out gambles on how the body is parsed, which
surfaces as literal `##` and `**` sitting in a comment under my name. Hand-rolled
ADF is verbose, easy to get subtly wrong, and markdown covers everything an audit
needs. A format mistake is invisible until it is posted, hence the read-back.

### Task rules

These four read in the order you execute them: pick the diff, write it up,
format it, sign it.

- **Audit only my own changes.** The subject is what *I* wrote on the branch, not everything its diff against the base contains. Take the merge-base, list my commits (`git log --author="$(git config user.email)" $(git merge-base origin/HEAD HEAD)..HEAD`), and diff those. If that leaves nothing, say the branch has no commits of mine rather than widening the net to fill the report.
- **Audits are written for non-programmers.** Describe every change as observable behaviour: what the system did before, what it does now, and what to look at to confirm it. Cover *all* of them, including the mechanical ones. File paths, class and method names, and framework vocabulary go in a trailing parenthetical at most: "renamed `getClaimant()` to `getPolicyholder()` in `ClaimController`" tells that reader nothing, while "the claimant is now called the policyholder everywhere it appears on screen" tells them what to check. Use the voice of the `plain` skill, not a commit message.
- **Jira comments carry no AI byline.** The heading is `Audit of the code changes`. Strip the `AI-generated` label, and don't reinstate it as a footer or disclaimer.
- **Format Jira comments deliberately.** Always pass `contentFormat: "markdown"` to `addCommentToJiraIssue`, because the default varies when omitted. Write ordinary markdown: a `##` heading, `-` bullets, bold used sparingly. No hand-rolled ADF JSON, no diffs or code blocks. Read the comment back afterwards to confirm it rendered, and fix a mistake by passing `commentId` to update it in place, never by posting a second comment.

## Philosophy

The *curate context* paragraph used to send nearly everything to a subagent:
researching, exploring, tracing, testing, reviewing, searching and reading
documentation, with "if you find yourself asking yourself questions, that is the
signal to ask a subagent instead". Five of the custom agents also said "use
proactively" in their descriptions, `code-reviewer` after every code change and
`quick-lookup` for any single search. Together they turned one question into
several fresh agent runs, each paying for its system prompt and instructions
again. Both were narrowed on
2026-10-24: delegation is for broad or parallel work, and the agents run when
asked.

## Memory

The harness gives you the format and the path but not the point: a session that
re-derives what the last one worked out is a session wasted, and memory is the
only thing that survives a `/clear`, a compaction, or a day off. An approach ruled
out *and why* is the most expensive thing to rediscover, because nothing in the
tree records a road not taken. Write as you go because a session can end abruptly
and usually does.

A durable rule belongs in `CLAUDE.md` because it is version-controlled and
survives a rebuild. Memory carries *what we found*; `CLAUDE.md` carries *how I
want you to work*. A stale memory is worse than a missing one: it arrives
sounding established and costs a session to unpick. Keeping secrets out of memory
is the context curation rule applied across sessions rather than within one.

## Working philosophy in full

Software is grounded in philosophy. These are the considerations that make the
rules above make sense.

### Curate context — think in an agentic DAG

An agentic DAG is a structured workflow for AI agents built on one-way
dependencies and no loops: nodes (tasks or agents), directed edges (one-way
rules), and an acyclic structure that cannot spin forever.

Protect your context; it should stay factual and minimal. But every subagent
starts from nothing and pays for its own system prompt and instructions before it
does any work, so delegating costs more than doing the same thing here. Delegate
only when the work is broad, a sweep across many files or sources where only the
conclusion matters, or parallel, independent pieces that can run at the same
time. A lookup, a single search, or reading a file you already know about stays in
the main session. When you do delegate, scope it narrowly and require a factual
result.

### Boil the ocean

When planning, do not be afraid to suggest seemingly insane solutions when they
reveal a materially better direction. Explore broadly, then recommend and
implement only the scope justified by the current problem. We effectively have to
rethink and relearn what it means to build and innovate software. We value
flexible platforms, memory efficiency, low CPU usage, and developer experience;
when those goals conflict, make the trade-offs explicit and follow project
priorities.

### Fight for the "obvious" solution

Measure twice, cut once: understand the problem fully before building. Cleverness
happens when you haven't understood the problem fully. The biggest win for
simplicity is refusing to solve a problem we don't have. Good code is often the
simplest thing that delivers required functionality and measured performance while
respecting developer experience. Trade-offs are real: make them explicit and
choose according to project priorities. No bolt-ons or faking success. Push back
when you see a more obvious way. Remember the K.I.S.S. method. Keep. It. Simple.
Stupid.

## Context and settings maintenance

On 2026-10-25, specialized code, test, formatting, Git and audit rules moved here
verbatim from the global instructions, with read triggers left at their original
headings. This keeps the rules available before the relevant task without
loading every workflow into every session. Deployment history moved from the
repo's CLAUDE.md to setup/REFERENCE.md for the same reason.

Portable Claude preferences now live in .claude/settings.portable.json and are
merged by the shared installer. Sonnet replaces Opus as the routine default;
medium effort and existing output and compaction limits remain unchanged.
Use Opus explicitly for work that needs it. These defaults reduce model cost;
only reducing context and generated output directly reduces token counts.

On 2026-10-26 drona23/claude-token-efficient (MIT) was installed globally using
its README's "Option 1 - Universal": its root `CLAUDE.md`, verbatim as of
upstream commit c5f0c96, saved as `.claude/rules/token-efficient.md` and linked
to `~/.claude/rules/`. Claude Code loads every file there in every project, so
it applies everywhere without overwriting this file. Curling it to
`~/.claude/CLAUDE.md`, as the README's command would if pointed at the home
directory, follows the symlink and replaces this whole file with seven lines.
Merging its lines into this file was tried first and backed out so the vendored
copy stays upstream's file and a refresh is a plain diff.

It overlaps this file on purpose and in one place it is stricter. "No
em-dashes" is a flat ban, where *Write like a person* only rules out em dashes
used as all-purpose punctuation; the stricter rule is the one to follow. Codex
does not read `~/.claude/rules/`, so these seven lines reach Claude only.

Two upstream pieces were left out. Its `.claude/settings.json` PreCompact hook
runs `git add -A` and commits with `--no-verify` before every compaction, which
breaks the *Git* rules (never commit unless asked, never skip hooks). Its
`profiles/` are per-project-type variants rather than global rules. To refresh:

```sh
curl -fsSL https://raw.githubusercontent.com/drona23/claude-token-efficient/main/CLAUDE.md \
  | diff ~/dotfiles/.claude/rules/token-efficient.md -
```
