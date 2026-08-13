# Kenny's dotfiles

My personal dotfiles, for macOS. Take anything you want, but at your own risk.

You should first review the code and remove things you don't want or need.
Don't blindly use my settings unless you know what that entails.

## Installation

```sh
git clone https://github.com/kdbaustert/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent — safe to re-run, and re-running is how you update.
Existing real files are backed up (`.backup-<timestamp>`) before being replaced
by symlinks; existing symlinks are simply re-pointed.

It will ask for your sudo password up front, and it expects Apple silicon
(the `pay-respects` step is pinned to arm64 and skips itself elsewhere).

### What it does

- Installs the Xcode command line tools and Homebrew, then everything in
  `homebrew/Brewfile`
- Symlinks the root dotfiles and every `.config/*` entry into `$HOME`
- Installs `pay-respects` (pinned + checksummed) into `~/.local/bin`
- Clones the trapd00r `LS_COLORS` database as an alternative to the default
  vivid/Voltage one — see `themes/voltage.md`
- Bootstraps zinit and pre-installs/compiles the zsh plugins
- Builds the Voltage theme caches for `bat` and fast-syntax-highlighting
- Configures ClamAV (signatures, scheduled `freshclam`, `clamd`)
- Enables Touch ID for `sudo` via `/etc/pam.d/sudo_local`
- Points iTerm2 at `iterm/` for its preferences

### Optional setup scripts

The scripts in `setup/` are opt-in, because they change system defaults or
install a lot of global packages. Select them by name:

```sh
SETUP_SCRIPTS="npm composer" ./install.sh
SETUP_SCRIPTS=all ./install.sh          # macos npm composer mas gh-extensions
```

| Script             | Installs                                          |
| ------------------ | ------------------------------------------------- |
| `macos.sh`         | System defaults — **review this one before running** |
| `npm.sh`           | Global npm packages                               |
| `composer.sh`      | Global Composer packages                          |
| `mas.sh`           | Mac App Store apps (sign in to the App Store first) |
| `gh-extensions.sh` | GitHub CLI extensions                             |

## Layout

| Path         | Contents                                              |
| ------------ | ----------------------------------------------------- |
| `.config/`   | Everything symlinked to `~/.config`                    |
| `zsh/`       | Aliases, functions, zinit config, `extra/` snippets    |
| `homebrew/`  | `Brewfile`                                             |
| `setup/`     | The optional scripts above                             |
| `themes/`    | Voltage — the shared palette; see `themes/voltage.md`  |
| `clamav/`    | ClamAV config + the `freshclam` LaunchAgent            |
| `iterm/`     | iTerm2 preferences folder                              |
| `obsidian/`  | "Amethyst Night" theme                                 |

## Notes

**There are two Neovim configs, and they are not variants of each other.**
`.config/nvim` is hand-rolled: lazy.nvim, ~22 plugins, no vendored runtime, and
a ~15ms start. `.config/lvim` is LunarVim, an IDE layer with its own runtime
directory. The split is the point — `nvim` is the editor, `lvim` is there when
the batteries-included version is wanted, and neither can break the other.

They share exactly one thing: `.config/voltage.nvim`, the Voltage colorscheme
as a standalone plugin-shaped directory that both put on their runtimepath. It
lives outside both because two transcriptions of the same palette is the drift
`themes/voltage.md` exists to prevent.

`.config/nvim` splits into `lua/configs` (settings needing no plugin) and
`lua/plugins` (one file per concern, each returning a lazy spec). Language
servers come from Mason; formatters and linters deliberately do not — they are
the ones the Brewfile and `setup/npm.sh` already install, so the shell and the
editor run the same binaries. `lazy-lock.json` is tracked, so `:Lazy restore`
reproduces the plugin set exactly.

**LunarVim's runtime is not installed by `install.sh`, only its config.**
`.config/lvim` is symlinked like every other `.config` entry, but the editor
itself lives in `~/.local/share/lunarvim` and comes from upstream's installer,
which is not vendored here:

```sh
LV_BRANCH=master bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/master/utils/installer/install.sh)
```

Run that once on a new box, then `lvim`.

**It is `lvim`, not `nvim`.** LunarVim isolates itself: its shim sets
`NVIM_APPNAME=lvim` and starts Neovim against its own `init.lua`, so nothing in
`.config/lvim` is on the path of a bare `nvim`, and nothing in `.config/nvim`
is on the path of `lvim`. They are two separate editors that happen to share a
binary — see the next note. `$EDITOR` stays `nvim`.

The config LunarVim writes on first run is replaced by the symlink, and the
plugin set is pinned by the tracked `.config/lvim/lazy-lock.json` — `:Lazy
restore` reproduces it exactly. The formatters and linters it wires up are the
ones already installed by the Brewfile and `setup/npm.sh`, not by Mason.
Upstream targets Neovim 0.10 while the Brewfile tracks current `neovim`, so
startup logs one harmless `vim.tbl_flatten is deprecated` warning from
LunarVim's own code.

**`obsidian/` is not deployed by `install.sh`.** Obsidian themes live at
`<vault>/.obsidian/themes/` and the vault path is per-machine; copy them in by
hand.

**Only `CLAUDE.md` is deployed out of `.claude/`.** It is symlinked to
`~/.claude/CLAUDE.md` — Claude Code's global instructions, applied to every
project. The rest of `~/.claude` is state Claude writes itself
(`settings.local.json`, `projects/`, `todos/`), so the directory is created and
linked *into* rather than linked over. `.claude/themes/` is kept here for
reference only; nothing links it.

**`iris` is on demand, not autostarted.** It wraps the shell rather than
plugging into zle, so leaving it in charge of every prompt fights atuin,
fzf-tab, zsh-autosuggestions and the alias table — the iris block in `.zshrc`
records what broke. `.zshrc` installs only its zle hooks, and only inside a
shell iris itself started, so typing `iris` gives you the full overlay and
exiting gives you your shell back.

**Don't run `iris setup` or `iris uninstall`.** Both rewrite your shell RC file
in place, and `~/.zshrc` is a symlink into this repo — they would edit the
tracked `.zshrc` rather than a copy. To remove iris, delete that block,
`brew uninstall versenilvis/iris/iris`, and drop `.config/iris`.

**No System Integrity Protection changes are needed.** Earlier versions of this
README opened with instructions to disable SIP; that was only ever required by
yabai's scripting addition. yabai and skhd have been removed, so nothing here
touches SIP any more — leave it on.

## Credits

Thanks to the [dotfiles community](https://dotfiles.github.io).
