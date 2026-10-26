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
- Shell is zsh. `~/.zshrc`, `~/.zprofile`, `~/.profile`, `~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`, `~/.prettierrc`, `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.override.md` (a second link to it), `~/.claude/REFERENCE.md`, `~/.claude/hooks/notify.sh`, `~/.claude/hooks/search-excludes.sh`, `~/.claude/hooks/resume-after-limit.sh`, `~/.claude/statusline.sh`, every `~/.claude/skills/<skill>` directory, every `~/.claude/rules/<rule>.md` file and every `~/.config/<tool>` entry are symlinks into `~/dotfiles`. Edit the file in `~/dotfiles`, never the path in `$HOME`.
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
| Find code by shape (calls, patterns) | `ast-grep run -p '$OBJ->save($$$)' -l php` (metavariables are uppercase; `$obj` matches only a variable named `$obj`) | regex in `rg`; `sg` (deprecated alias) |
| A symbol's definition, references, callers | the LSP tool (PHP, Swift; TS/JS only where the project has `typescript` installed) | `rg` for the name |
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
rg -n --max-columns=200 --max-columns-preview 'pattern'  # tracked, non-hidden
rg -n --max-columns=200 --max-columns-preview --hidden -g '!.git' 'pattern'
rg -nuu --max-columns=200 --max-columns-preview \
  -g '!{node_modules,vendor,build,out,public,storage,logs,tmp}' 'pattern'
fd -e ts 'name'                      # smart-case, .gitignore-aware
fd -H -I -E '{node_modules,vendor,build,out,public,storage,logs,tmp}' 'name'
```

The second `rg` adds dotfiles but still skips `.git`. The last `rg` ignores
`.gitignore` and includes hidden files; the last `fd` does the same and also
bypasses the global ignore.

Every `rg` carries `--max-columns=200 --max-columns-preview` so one minified
line can't flood the context. If the match sits past column 200, rerun with
`-o '.{0,40}needle.{0,40}'`.

**Never search `node_modules`, `vendor`, `build`, `out`, `public`, `storage`,
`logs` or `tmp`.** Exclude all eight by name whenever you widen a search, as
above, and in any search you hand the Grep or Glob tool or a subagent. A
PreToolUse hook rejects a widened `rg` or `fd` that leaves one out. The
exception is a task about something inside one of them: search only that
folder. A project's own `.ignore` lists its other noise, and `rg`, `fd` and the
Grep tool read it with no flags.

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
- **Verify before done.** Re-check each requirement, run typecheck, tests and lint, and state what changed, what was verified, and what could not be. When something fails, show me the actual command output — don't paraphrase a test failure. When I say "skip verification", skip the test, lint and `./build.sh --install` steps for that task and say in one line what went unchecked.
- **Ask before destructive or hard-to-reverse actions:** deleting files or branches, force pushes, hard resets, `--no-verify`, dropping DB tables, `brew uninstall`.
- **Stop and re-plan when it goes sideways.** Don't keep pushing an approach that isn't working — say what broke, say what you'd try instead, and let me redirect before you spend another five tool calls on it.
- **Be direct.** Skip preamble and don't restate my request back to me.
- **Write like a person, not a model.** This covers anything I read or publish: replies, commit messages, audits, Jira comments, and copy that goes on a page. Avoid the tells. That means em dashes used as all-purpose punctuation, lists of three for rhythm, "not X, it's Y", a tidy last line that restates the paragraph, colon reveals, and words like *robust*, *seamless*, *leverage*, *elevate* and *crafted*. Use plain words and sentences of different lengths, and claim nothing that isn't true. A reader who spots one tell stops trusting the rest, and on my site or under my name that costs more than the sentence was worth.
- **Be efficient.** Parallelize independent tool calls; serialize dependent ones. Everything a tool returns stays in the conversation and is paid for again on every turn after it, so:
  - Find where something lives with `rg -l` or `rg -c` first, then read only the lines you need.
  - Don't re-read a file that is already in the conversation or that you just edited.
  - Run the narrowest test or lint that covers the change, and pipe long output through `tail`.
  - Ask for the compact form first: `git diff --stat` before the full diff, `git log --oneline`, `phpunit --no-progress`, `vitest --reporter=dot`, `jest --silent`. Expand only the part that needs it.
  - Keep replies short: the answer, then what changed and what was checked.
  - When a long session turns to unrelated work, say so and suggest a fresh session or `/compact`. Every turn resends the whole history, so old context costs more than any single search.

## Code style

Before writing or changing code, read **Code style** in `~/.claude/REFERENCE.md`.

## Tests

Before adding or changing tests, read **Tests** in `~/.claude/REFERENCE.md`.

## Linters and formatters

Before selecting or running a formatter, linter or build/install command, read
**Linters and formatters** in `~/.claude/REFERENCE.md`. Parse shell edits with
`bash -n` / `zsh -n` and lint them with `shellcheck`.

## Git

Before a Git task, read **Git** in `~/.claude/REFERENCE.md`. Never commit, push
or create a PR unless asked. Never create a branch, disable signing, add
attribution trailers, or merge `develop` or `staging` into another branch.

## Audits and Jira comments

Before an audit or Jira comment, read **Audits and Jira comments** in
`~/.claude/REFERENCE.md`. Audit only my own changes and write for non-programmers.
Do not post a comment unless asked.

## Memory

Write a memory when the next session would otherwise have to redo the work: a
measured number, a traced call path, a root cause, an approach ruled out *and
why*, a goal in flight with what is left of it, or a pointer with no home in the
repo. Write it the moment it is established, not at the end.

In a project, those findings go in its memory bank: `CLAUDE-*.md` files at the
repo root. Claude and Codex both read them, so whichever agent runs next starts
where the last one stopped. Create a file the first time it has something to
hold.

| File | Holds | Read it |
| ---- | ----- | ------- |
| `CLAUDE-activeContext.md` | The goal in flight, what's done, what's left | At the start of a task |
| `CLAUDE-patterns.md` | Conventions the code follows that one file won't show | Before writing code |
| `CLAUDE-decisions.md` | Choices made, and approaches ruled out *and why* | Before a design choice |
| `CLAUDE-troubleshooting.md` | Root causes and the fixes that worked | When debugging |
| `CLAUDE-config-variables.md` | Config and env variables, and what reads each | When touching config |
| `CLAUDE-temp.md` | Scratch | Only when I point at it |

Read only what the task needs and skip files that don't exist. The global git
ignore lists all six, so `rg`, `fd` and the Grep and Glob tools never see them:
open them by exact path. Never stage or commit one. Date each entry, and fix or
delete it when it turns out wrong. Claude's auto memory keeps what isn't about
the repo and never copies the memory bank. `/update-memory-bank` records a
session; the `memory-bank-synchronizer` agent checks the files against the code.

- **A durable rule belongs in this file, not in memory.** If a memory would begin
  "Kenny prefers…" or "always run…", propose it as a CLAUDE.md edit instead.
- **Recalled memories are dated, not authoritative.** Re-read any file, flag,
  version or command one names before acting on it, and delete the memory when it
  turns out wrong.

Never write anything sensitive — credentials, tokens, client data, or the work
identity in `~/.gitconfig-work`.

## Philosophy

Understand the problem before building. Explore broadly, then implement only
what the request justifies. Prefer simple solutions; explain trade-offs in CPU,
memory and developer experience against project priorities. Push back on
unnecessary complexity. Full reasoning is in **Working philosophy in full** in
`~/.claude/REFERENCE.md` when revising these principles.

Delegate only broad sweeps or independent parallel work, with a narrow scope
and factual result. Keep single searches and known-file reads in this session;
every agent pays its own startup context cost.
