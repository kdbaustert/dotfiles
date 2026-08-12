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

**`obsidian/` and `.claude/` are not deployed by `install.sh`.** Obsidian
themes live at `<vault>/.obsidian/themes/` and the vault path is per-machine;
copy them in by hand. `.claude/` is neither in the root-dotfiles list nor under
`.config/`, so nothing links it — it is kept here for reference only.

**Don't run `iris setup` or `iris uninstall`.** Both rewrite your shell RC file
in place, and `~/.zshrc` is a symlink into this repo — they would edit the
tracked `.zshrc` rather than a copy. The autostart hook is already declared by
hand (see the iris block in `.zshrc`); to remove iris, delete that block,
`brew uninstall versenilvis/iris/iris`, and drop `.config/iris`.

**No System Integrity Protection changes are needed.** Earlier versions of this
README opened with instructions to disable SIP; that was only ever required by
yabai's scripting addition. yabai and skhd have been removed, so nothing here
touches SIP any more — leave it on.

## Credits

Thanks to the [dotfiles community](https://dotfiles.github.io).
