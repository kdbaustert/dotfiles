# Global instructions

Applies to every project. Project-level `CLAUDE.md` files take precedence over anything here.

The tooling contract below used to live in a sibling `AGENTS.md` that this file
pulled in with an `@AGENTS.md` import. That split is gone by choice: Claude Code
has no AGENTS.md discovery path at either scope — verified against 2.1.231,
neither `~/.claude/AGENTS.md` nor `<project>/AGENTS.md` is read — so the file only
ever loaded *because* of the import, and deleting that one line lost the rules
silently rather than erroring. One file, no import, nothing to keep in sync.

## Preferences

- Ask before committing to git
- Prefer editing existing files over creating new ones
- Run tests after making changes
- Keep code simple — no over-engineering
- No unnecessary comments or docstrings

## Workflow

- When something goes sideways, stop and re-plan — don't keep pushing
- After finishing a task: run typecheck, tests, and lint before calling it done

## Style

- Prefer small, focused functions
- Use early returns over nested conditionals

## Environment

- macOS, Apple Silicon. Homebrew at `/opt/homebrew` — always prefer its binaries over `/usr/bin`.
- Shell is zsh. `~/.zshrc`, `~/.zprofile`, `~/.profile`, `~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`, `~/.prettierrc`, `~/.claude/CLAUDE.md` and every `~/.config/<tool>` entry are symlinks into `~/dotfiles` — edit the file in `~/dotfiles`, never the symlink target path in `$HOME`.
- Editor is `nvim`. There is no Python version manager — `pyenv` was removed because it managed zero versions; `python3` is Homebrew's.
- **`node` is version-skewed by shell type.** `nvm` is lazy-loaded (`NVM_LAZY_LOAD` in `.zprofile`, turbo-deferred in `zsh/zinit.zsh`) and is a shim *function*, not a binary. It manages one version, v26.5.0. Non-interactive shells and scripts — which is what a Bash tool call is — never load the plugin and get Homebrew's `/opt/homebrew/bin/node`, currently v26.7.0 (measured). An interactive shell gets the shim and v26.5.0. So a version you observe through a tool call is not the version I get at a prompt; `whence -w node` in a real interactive shell is the only honest check, not `zsh -i -c`, which exits before turbo fires.
- Shell history is `atuin`.

GNU `coreutils`, `grep` and `gnu-sed` are installed but `gnubin` is deliberately
off `PATH`: the defaults are BSD, and the GNU versions are **g-prefixed** —
`ggrep`, `gsed`, `gls`, `gsort`, `gdircolors`. If a script needs GNU flags
(`sed -i` without an argument, `grep -P`), call the `g`-prefixed binary
explicitly rather than assuming. There is no `gfind` — `findutils` is not
installed, so `find` is always BSD `find`. Reach for `fd` instead.

Interactive aliases *do* reach non-interactive tool calls via the shell snapshot.
That is a hazard, not a convenience: `ls` is `eza`/`lsd` with icons, and `tree` —
which is not installed as a binary — resolves to the `llt` alias. **When parsing
output, call the real binary** — `/bin/ls`, or better, `fd`.

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

Also installed and worth knowing: `fzf`, `zoxide`, `delta`, `lazygit`, `gitui`,
`glow`, `yazi`, `btop`, `httpie` (the binary is `http`), `zstd`, and `sevenzip`
(the binary is `7zz` — there is no `7z`). Homebrew's `sqlite` is keg-only and
therefore off `PATH`, so a bare `sqlite3` is macOS's older system copy; call
`/opt/homebrew/opt/sqlite/bin/sqlite3` when the version matters.

The flags worth remembering:

```bash
# ripgrep — content
rg -i "pattern"           # case-insensitive
rg -t py "pattern"        # only Python files (`rg --type-list` for the rest)
rg -g "*.md" "pattern"    # only Markdown
rg -l "pattern"           # filenames with matches, no match text
rg -c "pattern"           # count per file
rg -n "pattern"           # line numbers
rg -A3 -B3 "error"        # context lines
rg "TODO|FIXME|HACK"      # alternation — one pass, not three

# ripgrep — file listing
rg --files                # every file (respects .gitignore)
rg --files -t md          # only Markdown
rg --files | rg "name"    # find by name

# fd
fd -e js                  # every .js file
fd . -t d                 # every directory
fd -x command {}          # run a command per match

# jq
jq . data.json            # pretty-print
jq -r .name file.json     # extract a field
jq '.id = 0' x.json       # modify a field
```

Search strategy: start broad then narrow (`rg "partial" | rg "specific"`), filter
by type early, batch alternations into one pattern, and scope to a subdirectory
when you know where to look.

## The gotcha that actually bites

**`rg` and `fd` both respect `.gitignore` and both skip hidden files.** A search
that comes back empty may be a search that never looked. When the target could be
ignored or vendored — `node_modules`, `vendor`, `dist`, build output, lockfiles,
anything under a dot-directory — pass the flags:

```sh
rg -n 'pattern'                      # default: tracked, non-hidden
rg -n --hidden -g '!.git' 'pattern'  # include dotfiles, still skip .git
rg -nuu 'pattern'                    # ignore .gitignore AND include hidden
fd -e ts 'name'                      # smart-case, .gitignore-aware
fd -H -I 'name'                      # hidden + no-ignore (also bypasses the global ignore)
```

`rg -l` for the file list alone, `rg -c` for counts — cheaper than dumping matches
when you only need to know where something lives.

`fd` also reads a **global ignore** at `.config/fd/ignore` (deployed to
`~/.config/fd/ignore`, read automatically with no env var wiring it up). It
excludes `.git/` and `.DS_Store` and nothing else — that is signal-to-noise, not
speed: `--hidden` was making CTRL-T list 501 files in `~/dotfiles` of which 415
were `.git/` internals. `node_modules/`, `vendor/` and `dist/` are deliberately
*not* in it, so the advice above still holds for them. `-I` bypasses the global
ignore along with `.gitignore`.

## Where things live

- `~/Development/` — web/PHP work. `cnc-claims` is the checked-out work project (custom PHP MVC; see `~/Development/cnc-mvc-ruleset.md` and the repo's own `CLAUDE.md`); `cnc-claimsource` is a sibling work project, currently present only as a zip. `kennybdev` is personal.
- `~/Developer/` — Swift/macOS and native projects (`Cmd-Tab`, `rio`, `ghostty`).
- `~/dotfiles/` — shell, git, and editor config.

## How I want you to work

These used to be two lists — "Rules" and "Working preferences" — that said the
same thing twice with two different sets of examples. One list, so there is only
ever one place to change a rule.

## Investigation & Accuracy

- Never speculate about code you have not read. Read files and ripgrep for usages before making claims
- If the user references a file, read it before answering
- If uncertain, say so and propose how to verify. Do not fabricate APIs, paths, or behavior

- **Investigate first.** Never speculate about code you have not read. Read files and `rg` for usages before making claims. If uncertain, say so and propose how to verify.
- **Scope to the request.** Do what is asked; nothing more. Don't refactor adjacent code or create abstractions for a single use. Default to research and recommendations — only edit when explicitly asked. If the ambiguity would change the work materially, ask once up front rather than guessing and rewriting later.
- **File discipline.** Edit existing files in place; don't create new ones unless required. No README or summary markdown unless I ask. Clean up scratch files.
- **Verify before done.** Re-check each requirement, run tests and lint, and state what changed, what was verified, and what could not be. When something fails, show me the actual command output — don't paraphrase a test failure.
- **Ask before destructive or hard-to-reverse actions:** deleting files or branches, force pushes, hard resets, `--no-verify`, dropping DB tables, `brew uninstall`.
- **Be direct.** Skip preamble and don't restate my request back to me.
- **Be efficient.** Parallelize independent tool calls; serialize dependent ones.

## Code style

Follow the repo's existing style first. Absent a repo convention:

- 2-space indent, LF line endings, UTF-8, final newline, no trailing whitespace. CSS/SCSS use tabs (4).
- JS/TS: single quotes, no semicolons, 80 cols, `es5` trailing commas, arrow parens omitted for single args — i.e. run Prettier with `~/.prettierrc`.
- PHP: 120 cols, double quotes, no trailing commas, PHP 8.1 target.
- Swift: standard Swift API design guidelines; no third-party formatter unless the repo ships one.

## Linters and formatters

Installed as real binaries, not editor-managed: `shellcheck`, `shfmt`, `stylua`,
`php-cs-fixer` from Homebrew, plus Prettier as a pnpm global (`~/Library/pnpm/bin`)
reading `~/.prettierrc`. The shell and the editor run the same binaries on
purpose — Neovim's Mason provides language servers only. Prefer a repo's own
pinned tooling when it ships one.

Verify shell edits without executing them: `bash -n` / `zsh -n` to parse,
`shellcheck` to lint.

## Git

- Commits are SSH-signed via 1Password (`op-ssh-sign`). Do not disable signing or add `-c commit.gpgsign=false` to work around a signing prompt — tell me instead.
- Personal identity is `kenny@kennyb.dev`; Bitbucket remotes auto-switch to the work identity via `~/.gitconfig-work` (a plain file in `$HOME`, deliberately not in the dotfiles repo). Don't set `user.email` per-repo by hand.
- Never commit, push, or create a PR unless I ask.
- **No co-author trailers.** Commit messages end at the last line of prose — no
  `Co-Authored-By:`, no "Generated with Claude Code" in a PR body, no attribution
  footer of any kind. This overrides the harness default, which appends one.
  `attribution.commit`/`attribution.pr` are set to `""` in `~/.claude/settings.json`
  to enforce it, but that file is untracked, so the rule lives here too.
- **Never create a branch.** Commit on whatever branch I'm already on, including the
  default branch — this overrides the harness default of branching first when on
  `main`/`master`. If a commit really shouldn't land on the current branch, say so
  and let me decide; don't run `git checkout -b`/`git switch -c` on your own.
- Work repos use Bitbucket Pipelines (`bitbucket-pipelines.yml`), not GitHub Actions — check the right CI config.
- `delta` is **not** git's pager here — it is invoked explicitly by the fzf-tab previews in `.zshrc`. So `git diff` and `git show` emit plain, parseable output; no `--no-pager` dance is needed. Add `--no-pager` anyway when piping a command whose pager behaviour you have not checked.

## Philosophy

Software is grounded in philosophy. These are the considerations that make the
rules above make sense.

### Curate context — think in an agentic DAG

An agentic DAG is a structured workflow for AI agents built on one-way
dependencies and no loops: nodes (tasks or agents), directed edges (one-way
rules), and an acyclic structure that cannot spin forever.

Curate your context by delegating tasks — researching, exploring, tracing,
testing, analyzing, reviewing, searching, reading documentation — to subagents and
subagent workflows. Protect your context; it should stay factual and minimal. A
clean context is rewarded with understanding, clarity, and success. Be smart and
intentional about the workflows you design. If doing a task in the main context
risks introducing conflated, uncertain, or unrelated information, delegate it and
require a factual, scoped result. If you find yourself asking yourself questions,
that is the signal to ask a subagent instead.

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
