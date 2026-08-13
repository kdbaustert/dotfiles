# AGENTS.md

Global tooling contract, applied to every project. Loaded by Claude Code via the
`@AGENTS.md` import in `.claude/CLAUDE.md`; read directly by tools that look for
`AGENTS.md`. Preferences and project layout live in `CLAUDE.md` — this file is
only about which binary to reach for.

## Environment

macOS, Apple silicon. Prefer `/opt/homebrew` binaries over `/usr/bin`.

GNU `coreutils` and `grep` are installed but `gnubin` is deliberately off `PATH`:
the defaults are BSD, and the GNU versions are **g-prefixed** — `ggrep`, `gsed`,
`gfind`, `gdircolors`. If a script needs GNU flags (`sed -i` without an argument,
`grep -P`), call the `g`-prefixed binary explicitly rather than assuming.

Shell is zsh, and interactive aliases *do* reach non-interactive tool calls via
the shell snapshot. That is a hazard, not a convenience: `ls` is `eza`/`lsd` with
icons and `tree` is aliased to `llt`. **When parsing output, call the real binary**
— `/bin/ls`, or better, `fd`.

## Reach for these first

| Task | Use | Not |
| ---- | --- | --- |
| Search file contents | `rg` | `grep -r`, `find -exec grep` |
| Find files by name | `fd` | `find` |
| JSON | `jq` | `sed`/`grep` over JSON |
| Shell history | `atuin search` | grepping `~/.zsh_history` |
| GitHub (PRs, issues, API) | `gh` | scraping web URLs |
| Read a file | the Read tool | `cat`, `bat`, `head` |
| Processes | `procs` | `ps aux \| grep` |

Also installed and worth knowing: `fzf`, `zoxide`, `delta`, `lazygit`, `gitui`,
`glow`, `yazi`, `btop`, `httpie`, `sqlite`, `zstd`, `sevenzip`.

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
fd -H -I 'name'                      # hidden + no-ignore
```

`rg -l` for the file list alone, `rg -c` for counts — cheaper than dumping matches
when you only need to know where something lives.

## Linters and formatters

Installed as real binaries, not editor-managed: `shellcheck`, `shfmt`, `stylua`,
`php-cs-fixer`, plus Prettier via `~/.prettierrc`. The shell and the editor run
the same binaries on purpose — Neovim's Mason provides language servers only.
Prefer a repo's own pinned tooling when it ships one.

Verify shell edits without executing them: `bash -n` / `zsh -n` to parse,
`shellcheck` to lint.

## Git

`delta` is **not** git's pager here — it is invoked explicitly by the fzf-tab
previews in `.zshrc`. So `git diff` and `git show` emit plain, parseable output;
no `--no-pager` dance is needed. Add `--no-pager` anyway when piping a command
whose pager behaviour you have not checked.
