#!/usr/bin/env bash
#
# Splices the StevenBlack "unified + porn" blocklist into /etc/hosts between
# #BLOCKLIST-BEGIN# / #BLOCKLIST-END# markers. Re-running it swaps in a fresh
# copy of the list, which makes it the refresh command too:
#
#     ./setup/hosts.sh
#
# Spliced rather than symlinked or tracked. FlyEnv owns its own marker block in
# the same file (#X-HOSTS-BEGIN# … #X-HOSTS-END#) and rewrites it whenever a
# local site is added, so a symlink into this repo would have FlyEnv editing a
# tracked file, the hazard CLAUDE.md warns about. A tracked copy of the list
# itself would be ~150k lines, 4 MB, and stale within a week. So only this
# script is tracked: everything outside the markers, FlyEnv's block and Apple's
# localhost lines included, is carried through untouched.
#
# Refreshed weekly by a root LaunchDaemon, local.<user>.hosts-refresh, that
# install.sh generates and installs, then runs this once. A root job pulling a
# file off the internet into /etc/hosts is a worse trade than a list a few weeks
# old, unless it has guards. Two make it acceptable:
#
#   - The daemon runs a root-owned copy of this script in /usr/local/libexec,
#     never the file in ~/dotfiles. The repo is writable by anything running as
#     me, so pointing a root job at it would hand root to any process that can
#     edit a file in $HOME.
#   - Only "0.0.0.0 host" lines survive the filter below, so the worst a broken
#     or compromised upstream can do is block a site, never redirect one to an
#     address it controls. keep_reachable() then un-blocks the hosts that must
#     never go dark, the updater's own download host among them.
#
# Re-run install.sh after editing this. That re-copies it to the root location;
# until then the daemon keeps running the old copy.
#
# To undo it, delete the lines from #BLOCKLIST-BEGIN# to #BLOCKLIST-END#
# inclusive; nothing else in the file depends on them. To stop the schedule,
# as the user who ran install.sh:
#
#     label="local.$(id -un).hosts-refresh"
#     sudo launchctl bootout "system/$label"
#     sudo rm "/Library/LaunchDaemons/$label.plist" "/usr/local/libexec/$label"
set -uo pipefail

LIST_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts"
HOSTS=/etc/hosts
BEGIN_MARKER="#BLOCKLIST-BEGIN#"
END_MARKER="#BLOCKLIST-END#"

# A truncated download still parses as a valid hosts file, just a nearly empty
# one, and installing it would quietly turn the blocking off. The real list is
# ~150k entries; well under that means something went wrong upstream or on the
# way down.
MIN_ENTRIES=50000

# The daemon passes --scheduled so its log lines carry a date: launchd's log
# has no timestamps of its own, and that line is what shows whether the weekly
# job ran at all.
scheduled=false
[ "${1:-}" = "--scheduled" ] && scheduled=true

# keep_reachable
#   stdin:  "0.0.0.0 host" lines, one per line
#   stdout: the same lines, minus any host that must never be blocked
#
# Unattended, a list that one week started blocking raw.githubusercontent.com
# would also stop every later download, and nothing would say so.
#
# Google Analytics is let through too, so its web UI at analytics.google.com
# loads, along with gtag.js, which GA serves from googletagmanager.com.
# Deleting the lines from /etc/hosts by hand would only last until Monday's
# refresh put them back.
# google-analytics.com and googleanalytics.com match every subdomain, since
# upstream keeps adding new ones (region1.google-analytics.com is already in);
# the hosts under google.com are exact, so the rest of google.com stays blocked.
# The ad hosts under g.doubleclick.net stay blocked: they serve ads, not GA.
keep_reachable() {
  awk '
    BEGIN {
      protected["raw.githubusercontent.com"] = 1
      protected["analytics.google.com"] = 1
      protected["marketingplatform.google.com"] = 1
      protected["googletagmanager.com"] = 1
      protected["www.googletagmanager.com"] = 1
      protected["ssl-google-analytics.l.google.com"] = 1
      protected["www-google-analytics.l.google.com"] = 1
      domain_count = split("google-analytics.com googleanalytics.com", protected_domains, " ")
    }

    function is_protected(host,   i, domain) {
      if (host in protected) return 1
      for (i = 1; i <= domain_count; i++) {
        domain = protected_domains[i]
        if (host == domain || substr(host, length(host) - length(domain)) == "." domain) return 1
      }
      return 0
    }

    {
      for (i = 2; i <= NF; i++) {
        host = tolower($i)
        if (host != "" && !is_protected(host)) print "0.0.0.0 " $i
      }
    }
  '
}

if [ "${1:-}" = "--filter" ]; then
  keep_reachable
  exit 0
fi

$scheduled && echo "$(date '+%Y-%m-%d %H:%M') scheduled refresh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Retries because the scheduled run fires the moment the Mac wakes, usually
# before Wi-Fi has rejoined; without them that week's refresh is simply lost.
if ! curl -fsSL --retry 5 --retry-delay 30 --retry-all-errors \
  -o "$tmp_dir/upstream" "$LIST_URL"; then
  echo "Could not download $LIST_URL — /etc/hosts left unchanged." >&2
  exit 1
fi

# Only the 0.0.0.0 entries. Upstream's own header re-declares localhost and
# friends, which Apple's lines above the markers already cover, and ends with a
# self-referential "0.0.0.0 0.0.0.0" that blocks nothing. Trailing comments are
# stripped so every line is a bare "0.0.0.0 host".
grep '^0\.0\.0\.0 ' "$tmp_dir/upstream" \
  | grep -v '^0\.0\.0\.0 0\.0\.0\.0$' \
  | sed 's/[[:space:]]*#.*$//' \
  | keep_reachable >"$tmp_dir/entries"

entry_count="$(wc -l <"$tmp_dir/entries" | tr -d ' ')"
if [ "$entry_count" -lt "$MIN_ENTRIES" ]; then
  echo "Only $entry_count entries downloaded (expected $MIN_ENTRIES+) — /etc/hosts left unchanged." >&2
  exit 1
fi

# awk rather than sed for the strip: it prints every kept line with a newline,
# which also repairs a file whose last line has none. FlyEnv leaves its
# #X-HOSTS-END# marker that way, and a block appended straight after it would
# land on the same line.
{
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    index($0, begin) == 1 { skipping = 1 }
    !skipping { print }
    index($0, end) == 1 { skipping = 0 }
  ' "$HOSTS"
  echo "$BEGIN_MARKER StevenBlack/hosts unified + porn, fetched $(date +%Y-%m-%d)"
  cat "$tmp_dir/entries"
  echo "$END_MARKER"
} >"$tmp_dir/hosts.new"

# The date on the BEGIN line differs on every run, so compare without it; an
# unchanged list then needs no sudo and no cache flush.
if diff -q \
  <(grep -v "^$BEGIN_MARKER" "$HOSTS") \
  <(grep -v "^$BEGIN_MARKER" "$tmp_dir/hosts.new") >/dev/null; then
  echo "Blocklist already current ($entry_count entries)."
  exit 0
fi

# cp onto the existing file rather than mv: it keeps /etc/hosts's own owner,
# mode and inode, where mv would install a file owned by the temp dir's user.
if ! sudo cp "$HOSTS" "$HOSTS.bak" || ! sudo cp "$tmp_dir/hosts.new" "$HOSTS"; then
  echo "Could not write $HOSTS — left as it was (previous copy, if any, at $HOSTS.bak)." >&2
  exit 1
fi

# macOS caches resolver answers in mDNSResponder, so the new entries only take
# effect once it is told to drop them. Guarded on the binary rather than on the
# OS, so the script still runs clean anywhere else.
if command -v dscacheutil >/dev/null 2>&1; then
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
fi

echo "Blocklist installed: $entry_count entries (previous file at $HOSTS.bak)."
