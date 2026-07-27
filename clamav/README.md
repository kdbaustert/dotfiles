# ClamAV

On-demand virus scanning. There is **no real-time protection** here — ClamAV's
on-access scanning depends on Linux fanotify and does not work on macOS, so the
`OnAccess*` options in the sample config are dead weight on this machine.

## Layout

| Repo file | Symlinked to |
|---|---|
| `clamd.conf` | `/opt/homebrew/etc/clamav/clamd.conf` |
| `freshclam.conf` | `/opt/homebrew/etc/clamav/freshclam.conf` |
| `com.clamav.freshclam.plist` | `~/Library/LaunchAgents/com.clamav.freshclam.plist` |

Signatures live in `/opt/homebrew/var/lib/clamav` (~120 MB) and are **not** in
the repo. `install.sh` runs `freshclam` on first setup to fetch them.

Logs: `/opt/homebrew/var/log/clamav/`.

## Two moving parts

- **`clamd`** — the scanning daemon, started by `brew services` (as `$USER`, so
  at login rather than at boot). Keeps ~1.3 GB of signatures in RAM, which is
  why `clamdscan` returns in milliseconds and `clamscan` takes ~4 seconds.
- **`freshclam`** — the signature updater, run by launchd every 2 hours.

## Things that are the way they are for a reason

**`freshclam` is a launchd one-shot, not a daemon.** freshclam has its own
daemon mode (`-d`), but a long-lived freshclam holds an exclusive lock on its
log file, which makes a manual `freshclam` fail outright with `Failed to lock
the log file`. Scheduling one-shot runs via `StartInterval` means the process
exits between runs and manual updates just work. Don't add `-d` back.

**`NotifyClamd` is set in `freshclam.conf`.** clamd loads signatures into memory
at startup and never re-reads them on its own, so without this it keeps serving
whatever it loaded at boot — indefinitely. This makes freshclam poke it after
each successful update.

**`ConcurrentDatabaseReload no` in `clamd.conf`.** The default (`yes`) builds a
second full copy of the database before dropping the old one, so peak RSS goes
from ~1.3 GB to ~2.6 GB on every update. Trade-off is that scans block for a few
seconds during a reload, which doesn't matter for on-demand use.

**`AlertExceedsMax yes`.** Off by default, which means files over `MaxFileSize`
are silently skipped *and the scan still reports `OK`*. That's actively
misleading, so this turns the skips into visible warnings.

**`--fdpass` is mandatory with `clamdscan`.** clamd runs as `$USER`, so without
the passed file descriptor it can't open much outside your own files. The
`clamq` / `clamdl` aliases already include it.

**Full scans use `clamscan`, not `clamdscan`.** Same reason inverted: a
daemon-based full-disk scan would silently skip nearly all of the system. Only
root + the standalone scanner sees all of `/`. See `clamfull()` in
`zsh/functions.zsh`.

**The `/System/Volumes` exclusion matters on macOS.** The data volume is
firmlinked in at `/System/Volumes/Data`, so without excluding it a scan of `/`
walks the entire disk twice.

## Third-party signatures

ClamAV's own signatures skew Windows/email, so `freshclam.conf` pulls three
extra feeds via `DatabaseCustomURL` (~18.6k signatures on top of core):

| DB | Source | Sigs |
|---|---|---|
| `urlhaus.ndb` | abuse.ch | ~16,775 |
| `malwarehash.hsb` | Sane Security | ~1,031 |
| `rogue.hdb` | Sane Security | ~798 |

**Every one was false-positive tested before being added** — against
`~/Development` (4.4 GB) and `~/Downloads` (100,934 files / 7.71 GiB). Zero
hits. Do the same before adding a fourth:

    curl -sSL -o /tmp/new.ndb <url>
    clamscan -d /tmp/new.ndb -r -i ~/Development ~/Downloads

Two candidates were **rejected** by that test:

- **`rfxn.ndb`** (Linux Malware Detect) flagged `App/Core/App.php` in *both*
  `cnc-claims` and `cnc-claimsource` as `php.inject.v23au.578`. Verified false
  positive — no `eval`/`base64_decode`/superglobal patterns, git-tracked with
  ordinary feature history. It matches generic PHP framework idiom, so it would
  keep firing on your own code.
- **`winnow_malware.hdb`** (Sane Security) is 65 bytes with 0 signatures.

Sane Security's mirrors "reserve the right to block your IP address if you are
downloading too many times per hour." Their signatures publish hourly; the
LaunchAgent checks every 2h. **Don't lower `StartInterval` without re-reading
<https://www.sanesecurity.com/usage/>.** Also note `ftp.sanesecurity.net` does
not resolve — `mirror.rollernet.us` is a listed mirror that does.

## PUA detection

`DetectPUA yes` with an **allowlist** of categories, because most PUA classes
are unusable on a dev machine.

The categories were read out of the installed `daily.cvd`, not from
`clamd.conf.sample` — the sample's examples (`NetTool`, `PWTool`, `RAT`,
`Scanner`) no longer exist in the database at all. Real ones as of writing:

    Andr Cert Doc Email Embedded Html Java Js Osx Packed
    Pdf Php Rtf Spy Swf Tool Txt Unix Win

Included: `Osx`, `Unix`, `Spy`, `Andr`, `Win`. Omitted: `Packed` (matches legit
Go/Rust builds), `Tool` (admin/security tooling), `Js`/`Html` (every
`node_modules` tree), `Php` (ordinary framework code), `Doc`/`Pdf` (any PDF with
JavaScript).

To re-derive the list after a database update:

    cd $(mktemp -d) && sigtool --unpack /opt/homebrew/var/lib/clamav/daily.cvd
    grep -rhoE 'PUA\.[A-Za-z0-9_]+' . | sort -u

## Reading the results

`Heuristics.Limits.Exceeded.*` is **not a detection** — it means the file was
too big or held too many entries to scan, so it was skipped. `clamfull` counts
these separately and reports them as a `Note:`, never as an infection.

Three scanner quirks that make naive scripting wrong here, all verified:

- **`clamscan` exits `2` when only a limit is exceeded** — the same code it uses
  for real errors. So exit status alone can't distinguish "big git pack" from
  "scan failed"; `clamfull` decides from parsed output instead.
- **`clamscan` and `clamdscan` disagree on the tally.** `clamscan` keeps limit
  warnings out of `Infected files:`; `clamdscan` counts them in. A scan of
  `~/Development` reported `Infected files: 5` with zero actual detections.
- **Duplicate CLI options take the FIRST occurrence, not the last** — appending
  `--max-filesize` to override an earlier one silently does nothing.

Also note `AlertExceedsMax` in `clamd.conf` only governs the daemon.
`clamscan` needs the `--alert-exceeds-max` flag, which `clamfull` passes; miss
it and oversized files are skipped silently while the scan still reports `OK`.

## Known gaps

- **TCC.** Even under `sudo`, macOS blocks `~/Library/Mail`, `~/Library/Messages`
  and similar. They show up as permission-denied lines rather than being
  scanned. To cover them, grant Full Disk Access to
  `/opt/homebrew/bin/clamscan` (and `/opt/homebrew/opt/clamav/sbin/clamd` for
  the daemon) in System Settings → Privacy & Security.
- **macOS malware coverage is still thin** even with the third-party feeds
  above. ClamAV is a signature scanner, not behavioural — it will not catch
  anything novel. Treat it as a second opinion, not primary protection.
- **`clamd` starts at login, not boot**, because `brew services` was run without
  sudo. That's deliberate — running it as root would need Full Disk Access
  review anyway.

## Aliases

Defined in `zsh/aliases.zsh` under the ClamAV heading; the full-scan logic is
`clamfull()` in `zsh/functions.zsh`.

    clamf         full-disk scan → ~/clamav-full-scan.log
    clamq PATH    quick scan via daemon
    clamdl        scan ~/Downloads
    clamdb        update signatures now
    clamstatus    daemon status
    clamlog       follow the scan log
