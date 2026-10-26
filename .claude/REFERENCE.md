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

What the three commands in `CLAUDE.md` do, since the file now only shows them:
the first `rg` adds dotfiles but still skips `.git`; the second ignores
`.gitignore` and includes hidden files; the `fd` does the same and also
bypasses the global ignore below. A plain `rg -n --max-columns=200
--max-columns-preview 'pattern'` or `fd -e ts 'name'` covers tracked,
non-hidden files and needs no exclusions. The two plain examples and these
explanations were cut from `CLAUDE.md` on 2026-10-26 to shrink a file that
loads in every project.

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

**Be efficient, and the 2026-10-26 trim.** The whole section was shortened that
day because `CLAUDE.md` loads in every project. Every bullet kept its rule;
what moved here is the why. Tool output is paid for again on every later turn,
so a search that dumps 5k tokens early costs 5k on each call after it. The
model-switch warning comes from a measurement: switching Opus sessions to
Fable at 200-260k context drove 77% of a week's Fable tokens (2026-10-25), and
the cold cache means each later call pays full price on the whole context.
Browser and computer-use work grows context fastest because screenshots are
large, so page text comes first. "Show failing output verbatim" replaces "don't
paraphrase a test failure": a paraphrase hides the line that tells me what
broke. The writing bullet keeps a short tell list because Codex reads this file
as `AGENTS.override.md` but never reads `~/.claude/rules/`.

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

A confirmed force push is `git push --force-with-lease --force-if-includes`.
`--force-with-lease` alone compares against the remote-tracking ref, and the
`git fetch` people run before a rebase updates that ref, so the lease passes
and a teammate's commit is dropped without a word. `--force-if-includes` also
checks that the remote tip is in your reflog, which a fetch alone can't fake.

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

**The memory bank** comes from centminmod/my-claude-code-setup (MIT, George
Liu), as of commit `7d5c3743942606a9c5756de47ecdb41e2317c8b6`, 2026-10-26: the
six `CLAUDE-*.md` files and their "read when" column from
`CLAUDE-template-2.md`, the `memory-bank-synchronizer` agent and the
`update-memory-bank` command. It was adapted rather than vendored, so there's no
upstream copy to diff against. Refresh by reading upstream's files again and
deciding change by change. What was changed and why:

- **Out of git.** Upstream already says not to commit these files. Here that's
  done in `.config/git/ignore`, by exact name, because a `CLAUDE-*.md` glob
  would also ignore tracked files with that prefix (cnc-claims'
  `CLAUDE-REFERENCE.md`). The ignore has a side effect upstream doesn't
  mention: `rg`, `fd`, Grep and Glob all skip the files, which is why the rule
  says to open them by path. Two more costs of being untracked: `git clean
  -fdx` deletes the whole memory bank without asking, and a `git worktree`
  starts without one, since the files live only in the checkout that wrote
  them.
- **No mirroring into auto memory.** Upstream's "dual memory" copies every
  update into `memory/*.md` as a backup against a wiped `CLAUDE.md`. That
  contradicts this file's rule against saving what files already hold, doubles
  the tokens, and covers a case that can't happen here: the memory bank isn't
  in `CLAUDE.md`, and `CLAUDE.md` is tracked. Auto memory stays for what isn't
  about the repo, such as an external pointer.
- **The point is Codex.** Codex can't read Claude's auto memory. It does read
  this file, as `~/.codex/AGENTS.override.md`, so both agents follow the same
  memory bank rule and read the same files.
- **Never edits `CLAUDE.md`.** Upstream's command updates "CLAUDE.md and memory
  bank files", and its agent rewrites both. Here `CLAUDE.md` and `AGENTS.md`
  are tracked contracts, often shared, so both tools propose edits to them and
  leave the change to a person.
- **Not proactive.** Upstream's agent description says "use proactively", which
  invites unrequested spawns at a full agent's startup cost. This one runs when
  asked. Upstream's `CLAUDE-todo-list.md` and its roadmap and business-plan
  preservation rules were dropped; none of those files exist here.
- **Skipped:** the template's core rules (this file already has them, close to
  word for word), its progressive-disclosure table, and its backup
  section. Backups would only matter if these notes outgrew one machine.

`CLAUDE.md` used to show the six files as a table with a "holds" and a "read
it" column. On 2026-10-26 it became one sentence per file with the read-when
inline, which kept every name in backticks (the check below looks for them)
and cut the section from 2.1k to about 1.4k characters. The "holds" column
survives only where the name doesn't say it: activeContext and decisions.

`setup/check-memory-bank.sh` checks that the six names agree across
`.claude/CLAUDE.md`, the git ignore and the agent, and that the ignore leaves
`CLAUDE-REFERENCE.md` alone. With `--eval` it checks that Claude actually reads
`CLAUDE-activeContext.md` when asked about a project's current goal, and asks
Codex too when it's installed. The Codex half has never run, and a Codex pass
is weaker: Codex can `ls` the directory, so it proves the file is reachable,
not that the instructions sent it there.

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

## Code rules in full

The complete rule sets behind `rules/code-style.md`, moved here on 2026-10-26.
As two path-scoped rules they were about 29k characters (~7.2k tokens est.)
and loaded in nearly every dotfiles session, because `*.sh` and `*.zsh` are
on their path lists; the condensed rule is about a sixth of that. Read this
section for a refactor, a code review, concurrency work, or when the short
rule is unclear. Headings are demoted two levels from the originals.

### Clean Code

This file defines mandatory working rules for code you write or change in any project. Follow these instructions before making any code, test, refactor, or review change. Where a project's own `CLAUDE.md` or `AGENTS.md` disagrees, follow the project.

#### Priority and behavior

- Treat every unqualified rule in this file as `MUST`; treat `Prefer` as `SHOULD`; treat `Do not`, `Avoid`, and `Never` as `MUST NOT` unless the user explicitly overrides it.
- Prefer readability, maintainability, correctness, and safe change over cleverness or speed hacks.
- Optimize for the next human reader.
- When trade-offs exist, choose the option that reduces long-term complexity.
- Do not copy bad structure into new code just because it already exists nearby.
- Apply the Boy Scout Rule to the code the task changes: leave it cleaner than you found it. Code outside the task stays as it is; mention problems there instead of fixing them.

#### Core clean code principles

- Write code primarily for humans, not just for execution.
- Keep code simple, direct, and easy to modify.
- Avoid accidental complexity.
- Avoid surprising behavior.
- Prefer explicit intent over implicit magic.
- Prefer local reasoning: a reader should understand code with minimal jumping across files.
- Reduce technical debt instead of moving it around.

#### Naming rules

- Use intention-revealing names.
- Names must explain purpose, role, or behavior without requiring extra comments.
- Avoid misleading names, overloaded meanings, and visually confusable identifiers.
- Make distinctions meaningful. Do not create names that differ only cosmetically.
- Use pronounceable, searchable names.
- Avoid abbreviations unless they are established domain or platform standards.
- Avoid encodings in names, including type prefixes, implementation hints, and Hungarian notation.
- Avoid unnecessary context in identifiers.
- Add context through modules, classes, namespaces, or types when that is cleaner than longer names.
- Use one word per concept across the codebase.
- Do not use multiple synonyms for the same operation or concept.
- Do not reuse a familiar word for a different meaning.
- Class, type, and module names should be nouns or noun phrases.
- Function and method names should be verbs or verb phrases.
- Use problem-domain names for domain concepts.
- Use solution-domain names for technical concepts.
- Do not use cute, funny, cryptic, or private-joke names.

#### Function rules

- Keep functions small.
- Each function must do one thing.
- A function should have one clear reason to change.
- Keep each function at one level of abstraction.
- Organize code top-down so readers see the high-level story before details.
- Prefer descriptive names over short names.
- Minimize the number of parameters.
- Avoid boolean flag parameters. Split behavior into separate functions instead.
- Avoid output parameters unless language conventions make them necessary.
- Eliminate hidden side effects.
- Separate commands from queries.
- A function that answers a question should not also mutate state.
- Prefer exceptions or explicit result types over ad hoc error codes, according to project language norms.
- Isolate error handling from main logic.
- Eliminate duplication aggressively.
- Prefer straightforward control flow over clever control flow.
- Refactor deep nesting into clearer structure.

#### Comment rules

- Do not use comments to compensate for bad naming or bad structure.
- First improve the code, then decide whether a comment is still needed.
- Prefer self-explanatory code.
- Use comments only when they add information the code cannot express well.
- Good comment categories include:
  - legal or licensing requirements
  - non-obvious intent
  - important warnings or constraints
  - rationale for a surprising decision
  - clarification of external behavior or protocol assumptions
- Remove redundant, obsolete, obvious, noisy, and misleading comments in the code you change.
- Do not narrate the code line by line.
- Keep comments precise and maintain them when code changes.
- Avoid TODO comments unless they are actionable, specific, and necessary.

##### How comments read

Write every comment and docblock description the way a developer on the team would type it by hand. The tells in `~/.claude/rules/human-writing.md` apply here too, even though that file leaves code itself out.

- Say why the code is there or what a reader would trip over, in plain words, as you'd tell a colleague looking over your shoulder.
- Lead with the point. Drop openers like "This function", "This method is used to", "Helper that" and "Utility for".
- Keep it short and specific: name the real table, edge case, limit or ticket. One or two sentences covers most comments.
- Match the tone, casing and density of the comments already in the file.
- Don't restate the name or signature. A description that says nothing the name doesn't is noise; when the project requires a docblock, keep the type tags and make the description earn its line.
- Don't narrate history or the task: no "Updated to", "Added for the new feature", "Fixed bug where", "As requested". That belongs in the commit message.
- No marketing words (robust, seamless, comprehensive, elegant, gracefully), em dashes, emoji or markdown emphasis.

```
// Bad:  This function is responsible for robustly retrieving the user's claims.
// Good: Skips archived claims; the nightly export reads those separately.

// Bad:  Updated to use the new cache layer
// Good: Cached for 5 minutes because the carrier API allows 60 calls a minute.
```

#### Formatting and structure

- Use consistent formatting across the repository.
- Format code to reveal structure and intent.
- Keep related concepts close together.
- Keep files, classes, and functions reasonably small.
- Use vertical ordering to tell the story from higher level to lower level.
- Use indentation to clarify scope, not to hide complexity.
- Avoid excessive line length when it hurts readability.
- Avoid decorative alignment that is brittle during edits.
- Preserve a layout that supports fast scanning.

#### Objects, modules, and data structures

- Separate behavior-rich objects from plain data carriers intentionally.
- Do not mix data containers and business behavior arbitrarily.
- Hide implementation details behind clear interfaces.
- Expose behavior, not representation.
- Use DTO-like structures as simple carriers when appropriate.
- Avoid train-wreck call chains and unnecessary knowledge of internal structure.
- Respect loose coupling and local boundaries.
- Keep persistence, framework, and third-party details from obscuring business behavior or core logic.

#### Class and module design

- Keep classes and modules small.
- Each class or module should have one primary responsibility.
- Favor high cohesion.
- Split classes that accumulate unrelated behavior.
- Organize code so likely changes remain local.
- Public APIs should be small, obvious, and hard to misuse.
- Prefer composition over complex inheritance unless inheritance is clearly the simpler and more stable model.
- Keep constructors and setup logic from overwhelming domain behavior.

#### Error handling

- Design error handling deliberately.
- Keep the happy path easy to read.
- Provide enough context in error messages for diagnosis.
- Use error types or exception classes that support caller decisions.
- Do not return `null` or equivalent absence sentinels when a safer model exists.
- Do not pass `null` or equivalent invalid states unless the API explicitly models that case.
- Prefer exceptions, special cases, empty objects, or explicit optionality according to the codebase's language and conventions.
- Make resource cleanup and shutdown paths correct and visible.

#### Boundaries and external dependencies

- Isolate third-party libraries behind local adapters or wrappers when practical.
- Avoid coupling core logic directly to unstable external APIs.
- Create narrow interfaces around dependencies.
- Add learning tests or focused integration tests for tricky external behavior.
- When a dependency does not exist yet, define interfaces from local needs, not from guesses about future implementations.

#### System construction rules

- Separate constructing a system from using it.
- Keep object graph assembly, dependency injection, factories, and framework bootstrapping out of ordinary business behavior.
- Put startup wiring in an explicit main or composition area.
- Use factories when construction policy is meaningful or complex.
- Do not let cross-cutting concerns obscure ordinary code flow.
- Use standards, frameworks, proxies, or AOP-style mechanisms only when they add demonstrable value.
- Test-drive architectural decisions with executable slices, not only diagrams or configuration.
- Use domain-specific languages only when they make system intent clearer than general-purpose code.

#### Tests

- Treat tests as production-quality code.
- Keep tests clean, readable, deterministic, and maintainable.
- A test should communicate one main idea.
- Prefer simple setup and clear assertions.
- Avoid brittle tests coupled to irrelevant implementation details.
- Tests should be fast when possible.
- Tests should be isolated and order-independent.
- Tests should be self-checking.
- Add or update tests for behavior changes, bug fixes, and significant refactors.
- Do not ship code changes without proportionate validation.
- When fixing a bug, add a test that would have caught it, when feasible.

#### TDD and clean test rules

- Prefer writing a failing test before production code when the behavior can be specified clearly.
- Do not write production behavior beyond what a failing test or explicit requirement justifies.
- Keep tests small enough that a failure names one behavior or one concept.
- Prefer one assert or one conceptual assertion per test when that improves clarity.
- Use test names and test data that reveal the business or technical behavior under test.
- Build a small testing vocabulary or helper DSL when repeated setup hides intent.
- Keep test code clean; dirty tests reduce the ability to change production code safely.
- Avoid tests that require multiple manual steps to run.
- Use coverage patterns to find untested risk, not as a substitute for meaningful assertions.
- Treat ignored, flaky, or skipped tests as unresolved questions.

#### Concurrency and async work

- Do not introduce concurrency unless it provides a real benefit.
- Prefer simpler sequential code when it is sufficient.
- Minimize shared mutable state.
- Prefer immutability, message passing, or clear ownership boundaries.
- Keep synchronized or locked sections as small as possible.
- Be explicit about shutdown, cancellation, timeouts, and cleanup.
- Test concurrent behavior carefully where it matters.
- Know the execution model before changing concurrent code.
- Avoid dependencies between synchronized methods.
- Get non-concurrent behavior correct before adding threading.
- Make threaded code pluggable and tunable when its policy or concurrency level may vary.
- Run concurrency-sensitive tests under varied thread counts, schedules, and platforms where practical.
- Treat spurious failures as possible concurrency defects until evidence says otherwise.

#### Refactoring rules

When refactoring is the task:

- Refactor in small, safe steps.
- Preserve behavior while improving structure.
- First make it work, then make it right.
- Remove duplication, dead code, misleading abstractions, and special-case clutter.
- Rename aggressively when names are weak.
- Extract code when doing so improves cohesion and clarity.
- Inline abstractions that no longer earn their cost.
- Prefer the simplest design that passes all relevant tests.

#### Emergent design and successive refinement

- Prefer designs that run all relevant tests, remove duplication, express intent, and use the fewest necessary classes and methods.
- Refine code through working drafts rather than expecting the first version to be clean.
- When code starts rough, keep improving names, structure, and tests until intent is clear.
- Do not start a grand redesign when incremental refinement can recover the design safely.
- Use the Boy Scout Rule on the code the task changes, and mention problems outside it instead of fixing them.

#### Smells to detect and eliminate

Look for these issues in the code you write or change, and fix them there. Mention the ones you notice in surrounding code instead of fixing them:

- vague or misleading names
- duplicated logic
- oversized functions
- oversized classes or modules
- mixed abstraction levels
- hidden side effects
- boolean control flags
- long parameter lists
- deep nesting
- excessive conditionals that should be isolated or polymorphic
- comment-heavy code that should be refactored instead
- dead code and unused abstractions
- fragile tests
- environment-dependent tests without need
- unnecessary indirection
- accidental complexity
- coupling that spreads change broadly
- build or tests requiring more than one manual step
- code at the wrong level of abstraction
- base classes depending on derivatives
- transitive navigation through object internals
- artificial coupling between unrelated concepts
- hidden logical dependencies
- unimplemented obvious behavior
- incorrect boundary behavior
- overridden safeties
- magic numbers without named meaning
- negative conditionals that obscure intent
- ignored tests and insufficient boundary tests
- functions that require readers to understand an algorithm before they can trust the name

#### Change Process

For every non-trivial task:

1. Understand the intent and affected behavior.
2. Identify the simplest correct change.
3. Improve names before adding comments.
4. Keep edits localized when possible.
5. Add or update tests as needed.
6. Run relevant validation.
7. Review the diff for readability, duplication, and unnecessary complexity.
8. Ensure the code you changed is cleaner than before.

#### Implementation preferences

- Prefer explicit, boring, maintainable solutions.
- Prefer standard library and existing project patterns over new dependencies.
- Do not add a dependency unless it clearly reduces overall complexity.
- Reuse established project conventions unless they conflict with these rules or the user explicitly asks otherwise.
- Keep interfaces small.
- Keep state transitions obvious.
- Avoid premature optimization.
- Optimize only when there is evidence or a known requirement.

#### Review checklist

Before finishing, verify all of the following:

- Names reveal intent.
- Functions are small and focused.
- Classes and modules have clear responsibilities.
- Comments are necessary and accurate.
- Error handling is explicit and useful.
- Duplication was removed where reasonable.
- Tests cover the changed behavior appropriately.
- The code reads cleanly from top to bottom.
- The design is simpler or at least not more complex than before.
- The change follows existing project conventions.

#### Output Expectations

When making changes:

- Briefly explain what changed.
- State what tests or checks were run.
- Call out any unresolved risk, assumption, or trade-off.
- If a requested change conflicts with these rules, follow the user request but mention the conflict explicitly.

#### Hard rules

- Do not introduce misleading names.
- Do not keep duplicated logic without a strong reason.
- Do not add comments where better code would remove the need.
- Do not mix querying with mutation without a strong reason.
- Do not silently broaden scope beyond the requested task.
- Do not leave touched code less readable than before.

### Code Complete

#### Purpose

Code you write or change in any project follows **Code Complete** in the sense of Steve McConnell. Where a project's own `CLAUDE.md` or `AGENTS.md` disagrees, follow the project. In short:
apply disciplined software construction practices that reduce defects, improve readability, and produce robust code under real-world constraints.

All code generation, edits, and reviews must optimize for:
- low-defect construction
- readable and intention-revealing code
- controlled complexity
- defensive programming where appropriate
- strong routine and class design
- practical correctness over style theater

This file is a binding engineering policy: `MUST` is binding, `SHOULD` is a strong default, and `MUST NOT` is forbidden.

---

#### Primary Directive

Construction quality is not accidental.

When uncertain, choose the option that:
1. lowers defect probability
2. makes the code easier to inspect and reason about
3. reduces control-flow complexity
4. uses data and routines clearly
5. protects the program against invalid states and misuse

Do not optimize for cleverness, minimal keystrokes, or fashionable idioms at the cost of clarity.

---

#### Foundational Construction Rules

1. Write code primarily for human readers.
2. Favor clarity, locality, and explicitness over trickiness.
3. Keep control flow simple and visible.
4. Make correctness easier to achieve than incorrectness.
5. Use conventions consistently.

---

#### Construction Prerequisites and Decisions

1. Do not treat construction as isolated typing; verify that requirements, architecture, major risks, and coding conventions are clear enough for the change.
2. Resolve major construction decisions before large implementation work: language constraints, error policy, data representation, reuse strategy, integration approach, and testing approach.
3. Use upstream uncertainty as a reason to build a small validated slice, not as an excuse for speculative code.
4. Keep the software metaphor or design model only if it helps make concrete construction decisions.
5. Measure twice before cutting when an early decision will be expensive to reverse.

---

#### Pseudocode Programming Process

1. For complex routines, sketch the routine in precise pseudocode or comments before filling in details.
2. Refine pseudocode until it names the real steps at a consistent abstraction level.
3. Convert clear pseudocode into code and keep only comments that still add intent, constraints, or rationale.
4. Do not use pseudocode as a substitute for understanding the algorithm.

---

#### Routine Design Rules

1. Routines should have one clear purpose.
2. The routine name should describe the result or action precisely.
3. Keep the interface as small as practical.
4. Avoid long parameter lists and flag arguments.
5. Separate setup, validation, computation, and side effects when they are conceptually different.
6. Return values should be meaningful and hard to misuse.
7. Prefer guard clauses and straightforward structure over deeply nested logic.

Anti-patterns (MUST NOT):
- routines that do several unrelated things
- routines whose names describe implementation detail instead of purpose
- many hidden side effects
- boolean parameters that switch routine mode

---

#### Variable and Data Rules

1. Use names that reveal purpose and meaning.
2. Keep variable scope as small as practical.
3. Initialize variables deliberately.
4. Prefer named constants or stable values where a variable is not meant to change.
5. Avoid magic numbers and unexplained sentinel values.
6. Use stronger data types when primitives hide meaning.

Anti-patterns (MUST NOT):
- reused loop/index/temp variables beyond their purpose
- long-lived mutable locals carrying many meanings
- values whose units or semantics are unclear

---

#### Data Type Rules

1. Choose data types that make invalid or ambiguous values harder to represent.
2. Name constants for magic values, units, bounds, and sentinel meanings.
3. Use booleans only for true binary meanings; replace flag fields with clearer states when needed.
4. Use enumerations or named alternatives when a value belongs to a closed set.
5. Use arrays, records, maps, and tables only where their shape communicates the data meaning.
6. Encapsulate unusual data structures behind routines or types that reveal purpose.
7. Keep units, ranges, precision, encoding, and ownership visible near the data they affect.

---

#### Control Flow Rules

1. Prefer the simplest control flow that expresses the logic.
2. Keep nesting shallow when possible.
3. Replace complicated boolean logic with named predicates or clearer structure.
4. Use case/switch constructs only when they improve clarity.
5. Eliminate impossible paths and dead branches.
6. Avoid surprising exits unless they clarify the routine.

Anti-patterns (MUST NOT):
- deeply nested conditionals
- complicated loop exits with hidden state changes
- control flow dependent on side effects in expressions
- clever one-liners that obscure the logic

---

#### Statement, Conditional, and Loop Rules

1. Organize straight-line code so dependencies appear before use and related statements stay together.
2. Keep conditionals positive and direct when possible.
3. Put the normal path where readers can find it quickly.
4. Use loops with clear initialization, termination, and update rules.
5. Keep loop bodies focused; extract work when a loop hides several responsibilities.
6. Avoid unusual control structures unless they are clearer than ordinary alternatives.
7. Use table-driven methods when repeated branching is stable and the table can be validated.

---

#### Defensive Programming Rules

1. Validate inputs at trust boundaries.
2. Use assertions or invariant checks where programmer assumptions matter.
3. Distinguish between recoverable conditions and programming errors.
4. Fail in a way that preserves diagnosability.
5. Do not silently continue from corrupted or impossible state.

Anti-patterns (MUST NOT):
- assuming all callers are correct
- burying invalid state until it causes distant failures
- swallowing exceptions without context

---

#### Error Handling Rules

1. Handle errors at the right level of abstraction.
2. Preserve useful context.
3. Do not let error handling dominate the normal path.
4. Standardize similar failure handling.
5. Prefer explicit, well-understood failure semantics over ad hoc conventions.

---

#### Table-Driven and Data-Driven Rules

1. Prefer data-driven logic over long repeated condition chains when the mapping is stable and explicit.
2. Use tables or maps for configuration-like decisions.
3. Keep the structure obvious and validated.
4. Do not hide complex logic in inscrutable data encodings.

---

#### Class and Module Design Rules

1. Each class or module should own a focused responsibility.
2. Separate interface from implementation.
3. Hide representation and incidental detail.
4. Keep classes cohesive.
5. Reduce coupling through clear contracts and limited knowledge of internals.

Anti-patterns (MUST NOT):
- god classes
- modules with mixed persistence, formatting, business logic, and integration concerns
- public surfaces that expose internal bookkeeping

---

#### Complexity Management Rules

1. Treat rising complexity as a defect risk.
2. Prefer simple code over clever code.
3. Break apart large or tangled routines and modules.
4. Remove duplication that multiplies maintenance effort.
5. Choose designs that reduce the amount a maintainer must keep in working memory.

---

#### Construction with Preconditions and Postconditions

1. Be explicit about routine assumptions.
2. Encode important invariants close to the code they protect.
3. Keep contracts simple and testable.
4. Use assertions for programmer mistakes, validation for external input, and domain errors for expected business failures.

---

#### Comment Rules

1. Comments should explain intent, rationale, contracts, and non-obvious facts.
2. Do not comment obvious code instead of improving it.
3. Keep comments accurate or delete them.
4. Prefer self-documenting structure first, comments second.

---

#### Coding Standards Rules

1. Be consistent within the codebase.
2. Use formatting, naming, and file structure to support readability.
3. Standardize common idioms so readers do not need to relearn style per module.
4. Prefer a shared convention over local personal taste.

---

#### Incremental Construction Rules

1. Build in small, verifiable increments.
2. Integrate frequently enough to surface conflicts and misunderstanding early.
3. Keep partial work from rotting in long-lived isolation.
4. Review and improve code as part of construction, not only after it.

---

#### Quality, Collaboration, Debugging, and Refactoring

1. Use reviews, inspections, pair work, tests, and static checks according to the risk of the code.
2. Treat debugging as diagnosis: reproduce, isolate, explain, fix, and verify rather than guessing.
3. Fix the root cause when practical, not only the symptom.
4. Add tests around defects so the same failure is easier to detect next time.
5. Refactor when structure hides intent, duplicates knowledge, or raises defect probability.
6. Keep refactoring separate from behavior changes when that improves reviewability.

---

#### Performance, Integration, Tools, and Craftsmanship

1. Do not tune performance until the requirement and evidence justify it.
2. When tuning is justified, measure before and after, and keep clarity unless the tradeoff is explicit.
3. Integrate frequently enough to expose construction conflicts early.
4. Use programming tools, scripts, debuggers, profilers, editors, and build automation to reduce error-prone manual work.
5. Keep layout and style consistent enough that readers can focus on meaning.
6. Prefer self-documenting code, but add documentation where the code cannot express intent, constraints, or usage.
7. Treat personal discipline, curiosity, and ability to withstand careful review as part of construction quality.

---

#### Review Rules

When reviewing code, actively look for:
- unclear names
- weak routine boundaries
- long parameter lists
- unnecessary nesting
- hidden side effects
- poor defensive checks at trust boundaries
- duplicated logic
- confusing control flow
- god classes or mixed responsibilities
- comments compensating for poor structure

---

#### Forbidden Patterns

##### Cleverness over Clarity
- dense tricks that are hard to inspect
- compressed expressions that save lines but increase interpretation cost

##### Routine Bloat
- one routine doing several phases and concerns
- long signatures with many unrelated parameters

##### Defensive Vacuum
- no validation at trust boundaries
- no checks around critical assumptions
- silent fallback from impossible state

##### Comment-as-Crutch
- obvious comments over bad code
- stale comments that mislead

##### Consistency Neglect
- arbitrary naming and formatting changes
- module-specific mini dialects inside one codebase

---

#### Code Generation Rules

When generating code, default to:
1. clear names
2. focused routines
3. explicit data meaning
4. simple control flow
5. defensive checks at boundaries
6. cohesive classes/modules
7. consistent style

Avoid by default:
- dense clever code
- broad god objects
- fragile hidden assumptions
- unnecessary complexity in loops and conditionals
- comments where better names or decomposition would do

---

#### Testing Rules

1. Test routine behavior around normal, boundary, and invalid inputs.
2. Test defensive checks where boundary validation matters.
3. Keep tests aligned with routine contracts.
4. Test complex data-driven logic with representative tables and edge cases.

---

#### Review Checklist

Before finalizing any change, verify:
- Are names clear and intention-revealing?
- Are routines focused and reasonably small?
- Is control flow straightforward?
- Are trust boundaries defended?
- Are contracts and invariants explicit enough?
- Did we reduce or at least not increase complexity?
- Are classes/modules cohesive?
- Did we avoid cleverness that harms inspection?
- Are comments used only where they add value?
- Is the style consistent with the rest of the codebase?

If any answer is no, revise before shipping.

---

#### Final Instruction

When uncertain, choose the option that:
1. lowers defect risk
2. improves readability
3. simplifies control flow
4. strengthens defensive correctness
5. keeps the code easier to inspect and maintain

Write code that would stand up to careful review.
