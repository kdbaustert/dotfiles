# Kenny's dotfiles v2 

A much more advanced dotfile setup & installer

## Under Development (Don't try running this yet)

My personal dotfiles. These are mine take anything you want, but at your own risk.

## Install

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
