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

Claude Code has no AGENTS.md discovery path at either scope — verified against
2.1.231, neither `~/.claude/AGENTS.md` nor `<project>/AGENTS.md` is read — so the
tooling contract lives in `CLAUDE.md` rather than in a sibling one pulled in by an
`@AGENTS.md` import, which went missing silently rather than erroring.

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

## Tests

Model-written tests have tells just as model-written prose does, and a reviewer
who spots them stops trusting that the suite checks anything. That is the reason
for matching the tests already in the repo so closely.

A fixed sleep in a browser test (`cy.wait(5000)`, `$browser->pause(2000)`) is
either longer than it needs to be, which slows the suite, or shorter, which makes
it flaky. A CSS path copied out of devtools breaks the next time someone moves
the layout.

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
