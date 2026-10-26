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

- macOS, Apple Silicon, zsh, `nvim`, `atuin`. Homebrew at `/opt/homebrew` owns every global tool; prefer its binaries over `/usr/bin`. `python3` is Homebrew's.
- Nix is for per-project environments only: never `nix profile install` or `nix-env -i`. If a tool call lacks `nix-shell`, source `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`. direnv never fires in a tool call, so run `nix develop -c <cmd>`.
- Symlinks into `~/dotfiles`: `~/.zshrc`, `~/.zprofile`, `~/.profile`, `~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`, `~/.prettierrc`, `~/.codex/AGENTS.override.md`, every `~/.config/<tool>` entry, and in `~/.claude/` the `CLAUDE.md`, `REFERENCE.md`, `statusline.sh`, `hooks/*.sh`, `skills/<skill>` and `rules/<rule>.md`. Edit the file in `~/dotfiles`, never the `$HOME` path.
- The `node` a tool call sees is Homebrew's, not my interactive nvm one; read **Environment** in `~/.claude/REFERENCE.md` before stating my version.
- GNU tools are g-prefixed (`ggrep`, `gsed`, `gls`, `gsort`); the defaults are BSD. No `gfind`; use `fd`.
- `ls` and `tree` are aliases in tool calls. To parse output, call `/bin/ls` or `fd`.

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

**`rg` and `fd` respect `.gitignore` and skip hidden files**, so an empty
result may be a search that never looked. Widen it when the target could be
ignored or under a dot-directory. Every `rg` carries `--max-columns=200
--max-columns-preview`; for a match past column 200, use `-o '.{0,40}needle.{0,40}'`.

```sh
rg -n --max-columns=200 --max-columns-preview --hidden -g '!.git' 'pattern'
rg -nuu --max-columns=200 --max-columns-preview \
  -g '!{node_modules,vendor,build,out,public,storage,logs,tmp}' 'pattern'
fd -H -I -E '{node_modules,vendor,build,out,public,storage,logs,tmp}' 'name'
```

**Never search those eight folders.** Name all of them whenever you widen a
search, including one you hand Grep, Glob or a subagent; a hook rejects a
widened `rg` or `fd` that leaves one out. The exception is a task about one of
them: search only that folder. A project's `.ignore` lists its other noise and
is read with no flags.

## Where things live

- `~/Development/` — web/PHP work, including the work projects. `kennybdev` is personal.
- `~/Developer/` — Swift/macOS and native projects (`Cmd-Tab`, `rio`, `ghostty`).
- `~/dotfiles/` — shell, git, and editor config.

## How I want you to work

- **Investigate first.** Read the code, and any file I reference, before making claims about it. If unsure, say so and say how you'd verify; never invent APIs, paths or behavior.
- **Read `CLAUDE-REFERENCE.md` in full before planning or editing, when the repo root has one.** Only `CLAUDE.md` loads by itself.
- **Scope to the request.** Do what is asked, nothing more, and no abstractions for a single use. Default to research and recommendations; edit only when asked. If an ambiguity would change the work materially, ask once up front.
- **Find the smallest change that works.** Change only the files and lines that must change, then say what you left alone. No unrequested renames, reformatting, moves, single-use config or "while I'm here" fixes. If the minimal change papers over a real defect, say so and let me decide.
- **Clean up your own orphans, and only your own.** Remove what your edit left unused in the same pass. Mention pre-existing dead code; don't remove it.
- **File discipline.** Edit files in place and create new ones only when required. No README or summary markdown unless I ask. Clean up scratch files.
- **Stop what you start.** Before reporting done, stop every server, watcher and background job you started, and name any you leave running on purpose.
- **Verify before done.** Re-check each requirement, run typecheck, tests and lint, and say what changed, what was verified and what wasn't. Show failing output verbatim. When I say "skip verification", skip tests, lint and `./build.sh --install`, and say in one line what went unchecked.
- **Ask before destructive or hard-to-reverse actions:** deleting files or branches, force pushes, hard resets, `--no-verify`, dropping DB tables, `brew uninstall`.
- **Keep work code and secrets where they are.** In a work repo (its remote is Bitbucket), don't send code, data or screenshots to an artifact, Miro, Jira or any other outside service unless I ask. Never put a secret, token or `.env` value in a reply, commit, artifact or memory.
- **Stop and re-plan when it goes sideways.** Say what broke and what you'd try instead, and let me redirect.
- **Be direct.** No preamble, no restating my request. Name the file, function and line (`src/auth.ts:42`). Say plainly when something is broken. End with the next action, not a recap.
- **Write like a person, not a model,** in anything I read or publish. No em dashes as all-purpose punctuation, lists of three for rhythm, "not X, it's Y", a last line restating the paragraph, colon reveals, or words like *robust*, *seamless* and *leverage*. Claim nothing that isn't true. `~/.claude/rules/human-writing.md` has the full list.
- **Be efficient.** Parallelize independent tool calls. Tool output is resent on every later turn, so:
  - Locate with `rg -l` or `rg -c`, then read only the lines you need. Don't re-read a file already in the conversation.
  - Run the narrowest test or lint, pipe long output through `tail`, and ask for the compact form first (`git diff --stat`, `git log --oneline`, `phpunit --no-progress`, `vitest --reporter=dot`, `jest --silent`).
  - Keep replies short: the answer, then what changed and what was checked.
  - When a long session turns to unrelated work, suggest a fresh session or `/compact`.
  - Before a model switch past ~100k context, warn me: the new model starts with a cold cache. Suggest `/compact` or a fresh session with a handoff.
  - Suggest its own session for browser and computer-use work, and read page text (`get_page_text`, `read_page`) before taking a screenshot.

## Code style

Before writing or changing code, read **Code style** in `~/.claude/REFERENCE.md`
and follow `~/.claude/rules/code-style.md`. Claude Code loads it once it works
with a source file. Codex never reads `~/.claude/rules/`, so open it before
writing code.

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

Write a memory the moment you establish something the next session would
otherwise redo: a measured number, a traced call path, a root cause, an
approach ruled out *and why*, or a goal in flight and what's left of it.

In a project it goes in the memory bank at the repo root, which Claude and
Codex both read. Read `CLAUDE-activeContext.md` (goal, done, left) at the start
of a task, `CLAUDE-patterns.md` before writing code, `CLAUDE-decisions.md`
(choices, and approaches ruled out) before a design choice,
`CLAUDE-troubleshooting.md` when debugging, `CLAUDE-config-variables.md` when
touching config, and `CLAUDE-temp.md` only when I point at it. Skip missing
ones; create one the first time it has something to hold. They're globally
git-ignored, so search tools never see them: open them by exact path, and
never stage one. Date entries and fix or delete wrong ones. Auto memory keeps
only what isn't about the repo. `/update-memory-bank` records a session; the
`memory-bank-synchronizer` agent checks the files against the code.

- **A durable rule belongs in this file, not in memory.** Propose a "Kenny
  prefers…" or "always run…" memory as a CLAUDE.md edit instead.
- **Recalled memories are dated, not authoritative.** Re-read any file, flag,
  version or command one names before acting on it.
- Never write anything sensitive: credentials, tokens, client data, or the work
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
