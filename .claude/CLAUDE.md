# Global instructions

Applies to every project. Project-level `CLAUDE.md` files take precedence over anything here.

## Environment

- macOS, Apple Silicon. Homebrew at `/opt/homebrew` — always prefer its binaries over `/usr/bin`.
- Shell is zsh. `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.gitconfig`, `~/.editorconfig`, `~/.prettierrc` are all symlinks into `~/dotfiles` — edit the file in `~/dotfiles`, never the symlink target path in `$HOME`.
- Editor is `nvim`. Version managers: `pyenv` (Python), `nvm` (Node).
- Shell history is `atuin`. Prefer `atuin search` over `grep`-ing `.zsh_history`.

## Where things live

- `~/Development/` — web/PHP work. `cnc-claims`, `cnc-claimsource` are work projects (custom PHP MVC; see `~/Development/cnc-mvc-ruleset.md` and each repo's own `CLAUDE.md`). `kennybdev` is personal.
- `~/Developer/` — Swift/macOS and native projects (`Cmd-Tab`, `rio`, `ghostty`).
- `~/dotfiles/` — shell, git, and editor config.

# Philosophy

Software is grounded in philosophy. Here are important considerations that will help you be more effective.

## Agentic DAG (Directed Acyclic Graph) - a structured workflow pattern for AI agents using one-way dependencies and no loops. It relies on nodes (tasks or agents), directed edges (one-way rules), and an acyclic structure (no infinite loops).

Curate your context by delegating tasks (researching, exploring, tracing, testing, analyzing, reviewing, searching, and reading documentation) to subagents and subagent workflows. Protect your context, which should remain factual and minimal. A clean context is rewarded with understanding, clarity, and success. Be smart and intentional about the workflows you design. If performing a task in the main context risks introducing conflated, uncertain, or unrelated information, delegate it to a subagent and require a factual, scoped result. If you find yourself asking yourself questions due it may be more appropriate to ask a subagent.

## Boil the ocean

When planning, do not be afraid to suggest seemingly insane solutions when they reveal a materially better direction. Explore broadly, then recommend and implement only the scope justified by the current problem. We effectively have to rethink and relearn what it means to build and innovate software. We value flexible platforms, memory efficiency, low CPU usage, and developer experience; when those goals conflict, make the trade-offs explicit and follow project priorities.

## Code style

Follow the repo's existing style first. Absent a repo convention:

- 2-space indent, LF line endings, UTF-8, final newline, no trailing whitespace. CSS/SCSS use tabs (4).
- JS/TS: single quotes, no semicolons, 80 cols, `es5` trailing commas, arrow parens omitted for single args — i.e. run Prettier with `~/.prettierrc`.
- PHP: 120 cols, double quotes, no trailing commas, PHP 8.1 target.
- Swift: standard Swift API design guidelines; no third-party formatter unless the repo ships one.

## Git

- Commits are SSH-signed via 1Password (`op-ssh-sign`). Do not disable signing or add `-c commit.gpgsign=false` to work around a signing prompt — tell me instead.
- Personal identity is `kenny@kennyb.dev`; Bitbucket remotes auto-switch to the work identity via `~/.gitconfig-work`. Don't set `user.email` per-repo by hand.
- Never commit, push, or create a PR unless I ask. If I'm on the default branch, branch first.
- Work repos use Bitbucket Pipelines (`bitbucket-pipelines.yml`), not GitHub Actions — check the right CI config.

## Working preferences

- Be direct. Skip preamble and restating my request back to me.
- Prefer editing existing files over creating new ones. Don't write README or summary markdown files unless I ask.
- Show me the actual command output when something fails — don't paraphrase a test failure.
- Ask before destructive or hard-to-reverse actions (deleting files, force push, dropping DB tables, `brew uninstall`).
- If a task is ambiguous in a way that changes the work materially, ask once up front rather than guessing and rewriting later.

## Fight for the "obvious" solution

Measure twice, cut once: understand the problem fully before building. Cleverness happens when you haven't understood the problem fully. The biggest win for simplicity is refusing to solve a problem we don't have. Good code is often the simplest thing that delivers required functionality and measured performance while respecting developer experience. Trade-offs are real: make them explicit and choose according to project priorities. No bolt-ons or faking success. Push back when you see a more obvious way. Remember the K.I.S.S. method. Keep. It. Simple. Stupid.