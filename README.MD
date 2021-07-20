# Kenny's dotfiles 

My personal dotfiles. These are mine take anything you want, but at your own risk.

## Installation

You should first review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

#### Clone

```
git clone git://github.com/kdbaustert/dotfiles.git ~/dotfiles
```

### This setup requires Disabling System Integrity Protection

#### How do I disable System Integrity Protection?

1. Turn off your device
2. Hold down `command` `⌘R` while booting your device.
3. In the menu bar, choose `Utilities`, then `Terminal`

#### macOS 11.0.1

Requires Filesystem Protections and Debugging Restrictions to be disabled (workaround because --without debug does not work) printed warning can be safely ignored

```
csrutil disable --with kext --with dtrace --with nvram --with basesystem
```

#### macOS 10.14 and 10.15

Requires Filesystem Protections and Debugging Restrictions to be disabled (printed warning can be safely ignored)

```
csrutil enable --without debug --without fs
```

## Credits

Thanks to the [dotfiles community](https://dotfiles.github.io).
