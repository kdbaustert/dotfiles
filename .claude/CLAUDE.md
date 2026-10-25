# Global instructions

Applies to every project. Claude Code loads this file and the project's
`CLAUDE.md` together, this one first. Where they disagree, follow the project and
ignore the rule here; don't try to satisfy both. A project file that overrides a
rule should name the rule it overrides.

`~/.claude/REFERENCE.md` holds the measurements, history and reasons behind these
rules, under the same headings. It is not loaded automatically. Read the matching
section before changing or arguing with a rule here, and when a task touches Nix,
node versions, git signing identities, or Swift formatting and language modes.

## Environment

- macOS, Apple Silicon. Homebrew at `/opt/homebrew`; prefer its binaries over `/usr/bin`.
- Nix sits beside Homebrew and is for per-project environments only (`nix-shell`, `nix develop`). Homebrew owns every global tool, so never `nix profile install` or `nix-env -i` anything the Brewfile has. A tool call may not have `nix` at all: check with `command -v nix-shell`, and if it's missing, source `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` rather than splicing `/nix/...` into PATH by hand. direnv never fires in a tool call, so run `nix develop -c <cmd>` from the project.
- Shell is zsh. `~/.zshrc`, `~/.zprofile`, `~/.profile`, `~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`, `~/.prettierrc`, `~/.claude/CLAUDE.md`, `~/.claude/REFERENCE.md`, `~/.claude/hooks/notify.sh`, `~/.claude/statusline.sh`, every `~/.claude/skills/<skill>` directory and every `~/.config/<tool>` entry are symlinks into `~/dotfiles`. Edit the file in `~/dotfiles`, never the path in `$HOME`.
- Editor is `nvim`. No Python version manager; `python3` is Homebrew's.
- `node` differs by shell type. Tool calls get Homebrew's `/opt/homebrew/bin/node`; my interactive shell gets nvm's lazy-loaded version. So a version you see in a tool call may not be mine. `whence -w node` in a real interactive shell is the only honest check, since `zsh -i -c` exits before nvm loads.
- Shell history is `atuin`.

GNU `coreutils`, `grep` and `gnu-sed` are installed g-prefixed (`ggrep`, `gsed`,
`gls`, `gsort`) and the defaults are BSD. Call the g-prefixed binary when you need
GNU flags (`sed -i` without an argument, `grep -P`). There is no `gfind`; use `fd`.

Interactive aliases reach tool calls through the shell snapshot: `ls` is
`eza`/`lsd` with icons and `tree` is an alias. **When parsing output, call the
real binary**, `/bin/ls` or better `fd`.

## Reach for these first

| Task | Use | Not |
| ---- | --- | --- |
| Search file contents | `rg` | `grep -r`, `find -exec grep` |
| Find files by name | `fd` | `find` |
| List every file in a tree | `fd . -t f`, `rg --files` | `ls -R`, `tree` |
| List one directory | `/bin/ls -la` | the aliased `ls` |
| JSON | `jq` | `sed`/`grep` over JSON |
| Shell history | `atuin search` | grepping `~/.zsh_history` |
| GitHub (PRs, issues, API) | `gh` | scraping web URLs |
| Read a file | the Read tool | `cat`, `bat`, `head` |
| Processes | `procs` | `ps aux \| grep` |

Also installed: `fzf`, `zoxide`, `delta`, `lazygit`, `gitui`, `glow`, `yazi`,
`btop`, `httpie` (the binary is `http`), `zstd`, and `sevenzip` (the binary is
`7zz`; there is no `7z`). A bare `sqlite3` is macOS's older copy; call
`/opt/homebrew/opt/sqlite/bin/sqlite3` when the version matters.

## The gotcha that actually bites

**`rg` and `fd` both respect `.gitignore` and both skip hidden files.** A search
that comes back empty may be a search that never looked. When the target could be
ignored (`dist`, build output, lockfiles, anything under a dot-directory), pass
the flags:

```sh
rg -n 'pattern'                      # default: tracked, non-hidden
rg -n --hidden -g '!.git' 'pattern'  # include dotfiles, still skip .git
rg -nuu -g '!{node_modules,vendor,build,out,public,storage,logs,tmp}' 'pattern'
fd -e ts 'name'                      # smart-case, .gitignore-aware
fd -H -I -E '{node_modules,vendor,build,out,public,storage,logs,tmp}' 'name'
```

The last `rg` ignores `.gitignore` and includes hidden files; the last `fd` does
the same and also bypasses the global ignore.

**Never search `node_modules`, `vendor`, `build`, `out`, `public`, `storage`,
`logs` or `tmp`.** They hold third-party code, build output, uploads and logs,
and one hit in any of them buries the results that matter. `.gitignore` usually
keeps them out, but not every repo ignores them, and `-uu`, `-I` or a path passed
straight to the search lets them back in. So exclude all eight by name whenever
you widen a search, as above, and pass the same exclusions to the Grep and Glob
tools and to any subagent you hand a search. The one exception is a task about
something inside one of them, such as a dependency's source or a specific log.
Then search only that folder, not the whole tree.

Use `rg -l` or `rg -c` when you only need to know where something lives. `fd` also
reads a global ignore at `~/.config/fd/ignore` that excludes only `.git/` and
`.DS_Store`; `-I` bypasses it.

## Where things live

- `~/Development/` — web/PHP work. `cnc-claims` is the checked-out work project (custom PHP MVC; see `~/Development/cnc-mvc-ruleset.md` and the repo's own `CLAUDE.md`); `cnc-claimsource` is a sibling work project, currently present only as a zip. `kennybdev` is personal.
- `~/Developer/` — Swift/macOS and native projects (`Cmd-Tab`, `rio`, `ghostty`).
- `~/dotfiles/` — shell, git, and editor config.

## How I want you to work

- **Investigate first.** Never speculate about code you have not read. Read files and `rg` for usages before making claims, and read any file I reference before answering. If uncertain, say so and propose how to verify — don't fabricate APIs, paths, or behavior.
- **Read `CLAUDE-REFERENCE.md` before planning or editing, when the repo has one.** Claude Code auto-loads only `CLAUDE.md`, so a repo that splits its rules from its architecture reference (`cnc-claims` does) hands you half of what it wrote. Look for it at the repo root at the start of a task and read it in full before you plan or touch anything.
- **Scope to the request.** Do what is asked; nothing more. Don't refactor adjacent code or create abstractions for a single use. Default to research and recommendations — only edit when explicitly asked. If the ambiguity would change the work materially, ask once up front rather than guessing and rewriting later.
- **Find the smallest change that works.** Before editing, work out the minimal set of files and lines that has to change, and change only those. Then say what that scope was and what you left alone. Renames the task didn't need, reformatting lines you only read, moving code to where it 'should' live, config for a single call site and "while I'm here" fixes are all out. If the minimal change only papers over a real defect, say so and let me decide rather than widening scope yourself.
- **Clean up your own orphans, and only your own.** A change that leaves an import, variable or function unused is not finished — remove what *your* edit stranded, in the same pass. Pre-existing dead code is a different thing: leave it, and mention it, so removing it stays my call.
- **File discipline.** Edit existing files in place; don't create new ones unless required. No README or summary markdown unless I ask. Clean up scratch files.
- **Verify before done.** Re-check each requirement, run typecheck, tests and lint, and state what changed, what was verified, and what could not be. When something fails, show me the actual command output — don't paraphrase a test failure.
- **Ask before destructive or hard-to-reverse actions:** deleting files or branches, force pushes, hard resets, `--no-verify`, dropping DB tables, `brew uninstall`.
- **Stop and re-plan when it goes sideways.** Don't keep pushing an approach that isn't working — say what broke, say what you'd try instead, and let me redirect before you spend another five tool calls on it.
- **Be direct.** Skip preamble and don't restate my request back to me.
- **Write like a person, not a model.** This covers anything I read or publish: replies, commit messages, audits, Jira comments, and copy that goes on a page. Avoid the tells. That means em dashes used as all-purpose punctuation, lists of three for rhythm, "not X, it's Y", a tidy last line that restates the paragraph, colon reveals, and words like *robust*, *seamless*, *leverage*, *elevate* and *crafted*. Use plain words and sentences of different lengths, and claim nothing that isn't true. A reader who spots one tell stops trusting the rest, and on my site or under my name that costs more than the sentence was worth.
- **Be efficient.** Parallelize independent tool calls; serialize dependent ones. Everything a tool returns stays in the conversation and is paid for again on every turn after it, so:
  - Find where something lives with `rg -l` or `rg -c` first, then read only the lines you need.
  - Don't re-read a file that is already in the conversation or that you just edited.
  - Run the narrowest test or lint that covers the change, and pipe long output through `tail`.
  - Keep replies short: the answer, then what changed and what was checked.

## Code style

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

## Tests

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

These four read in the order you execute them: pick the diff, write it up,
format it, sign it.

- **Audit only my own changes.** The subject is what *I* wrote on the branch, not everything its diff against the base contains. Take the merge-base, list my commits (`git log --author="$(git config user.email)" $(git merge-base origin/HEAD HEAD)..HEAD`), and diff those. If that leaves nothing, say the branch has no commits of mine rather than widening the net to fill the report.
- **Audits are written for non-programmers.** Describe every change as observable behaviour: what the system did before, what it does now, and what to look at to confirm it. Cover *all* of them, including the mechanical ones. File paths, class and method names, and framework vocabulary go in a trailing parenthetical at most: "renamed `getClaimant()` to `getPolicyholder()` in `ClaimController`" tells that reader nothing, while "the claimant is now called the policyholder everywhere it appears on screen" tells them what to check. Use the voice of the `plain` skill, not a commit message.
- **Jira comments carry no AI byline.** The heading is `Audit of the code changes`. Strip the `AI-generated` label, and don't reinstate it as a footer or disclaimer.
- **Format Jira comments deliberately.** Always pass `contentFormat: "markdown"` to `addCommentToJiraIssue`, because the default varies when omitted. Write ordinary markdown: a `##` heading, `-` bullets, bold used sparingly. No hand-rolled ADF JSON, no diffs or code blocks. Read the comment back afterwards to confirm it rendered, and fix a mistake by passing `commentId` to update it in place, never by posting a second comment.

## Memory

Write a memory when the next session would otherwise have to redo the work: a
measured number, a traced call path, a root cause, an approach ruled out *and
why*, a goal in flight with what is left of it, or a pointer with no home in the
repo. Write it the moment it is established, not at the end.

- **A durable rule belongs in this file, not in memory.** If a memory would begin
  "Kenny prefers…" or "always run…", propose it as a CLAUDE.md edit instead.
- **Recalled memories are dated, not authoritative.** Re-read any file, flag,
  version or command one names before acting on it, and delete the memory when it
  turns out wrong.

Never write anything sensitive — credentials, tokens, client data, or the work
identity in `~/.gitconfig-work`.

## Philosophy

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
