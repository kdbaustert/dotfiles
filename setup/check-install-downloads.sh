#!/usr/bin/env bash
#
# Runs the download installers in setup/lib.sh against a stub curl and checks
# what they report. install_superfile: a failed download is a warning, never
# "superfile installed.", and a downloaded script runs with the failing sudo
# stub first on PATH. install_pay_respects: a bad checksum or an archive whose
# binaries can't be copied is a warning, never "installed.". Run it after
# changing either function:
#
#   setup/check-install-downloads.sh
#
# SC2016 is off because the stub bodies are meant to expand later, in the stub.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/install-downloads.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0

# With -o it copies $STUB_FILE there, like a curl that downloaded a release
# asset. Without it, it prints $STUB_SCRIPT and exits with $STUB_CURL_EXIT,
# like a curl that fetched (or failed to fetch) an install script.
mkdir -p "$tmp_dir/bin" "$tmp_dir/home" "$tmp_dir/assets"
cat >"$tmp_dir/bin/curl" <<'EOF'
#!/bin/bash
out=""
while [ $# -gt 0 ]; do
  [ "$1" = "-o" ] && out="$2"
  shift
done
if [ -n "$out" ]; then
  cp "$STUB_FILE" "$out" || exit 22
  exit 0
fi
printf '%s' "${STUB_SCRIPT:-}"
exit "${STUB_CURL_EXIT:-0}"
EOF
chmod +x "$tmp_dir/bin/curl"

# The clean PATH below has no Homebrew, and install_pay_respects skips itself
# without unzstd.
if ! unzstd_path="$(command -v unzstd)" || ! command -v zstd >/dev/null; then
  echo "zstd not installed (brew install zstd); can't build the pay-respects fixtures." >&2
  exit 1
fi
ln -s "$unzstd_path" "$tmp_dir/bin/unzstd"

# Sources lib.sh in a clean environment with no spf anywhere and prints what
# install_superfile said. STUB_CURL_EXIT and STUB_SCRIPT in the caller's
# environment reach the curl stub.
run_superfile() {
  env -i PATH="$tmp_dir/bin:/usr/bin:/bin" HOME="$tmp_dir/home" \
    STUB_CURL_EXIT="${STUB_CURL_EXIT:-0}" STUB_SCRIPT="${STUB_SCRIPT:-}" \
    /bin/bash -c 'DOTFILES_DIR="$1"; source "$1/setup/lib.sh"; install_superfile' \
    _ "$root" 2>&1
}

# Packs the named files, laid out like the real release (binaries at the top,
# pages under man/), into a .tar.zst and prints its path.
#
# @param $1 asset name
# @param $@ files to include, relative to the archive root
build_asset() {
  local name="$1" src="$tmp_dir/assets/$1.src" file
  shift
  mkdir -p "$src/man"
  for file in "$@"; do
    printf '#!/bin/sh\necho %s\n' "$file" >"$src/$file"
  done
  tar -cf - -C "$src" . | zstd -q -o "$tmp_dir/assets/$name.tar.zst"
  echo "$tmp_dir/assets/$name.tar.zst"
}

# Runs install_pay_respects against the given asset in a fresh HOME, so no case
# sees a pay-respects an earlier one installed, and prints what it said.
#
# @param $1 HOME directory name, under the scratch directory
# @param $2 asset path the curl stub hands back
# @param $3 sha256 the installer is told to expect
run_pay_respects() {
  mkdir -p "$tmp_dir/$1"
  env -i PATH="$tmp_dir/bin:/usr/bin:/bin" HOME="$tmp_dir/$1" STUB_FILE="$2" \
    /bin/bash -c 'DOTFILES_DIR="$1"; source "$1/setup/lib.sh"; install_pay_respects 0.8.8 "$2" "$3"' \
    _ "$root" "$3" "$(basename "$2")" 2>&1
}

# @param $1 file path
sha256_of() {
  shasum -a 256 "$1" | cut -d' ' -f1
}

# @param $1 description
# @param $2 text the output must contain
# @param $3 actual output
expect_text() {
  if [[ $3 == *"$2"* ]]; then
    printf 'ok:   %s\n' "$1"
  else
    printf 'FAIL: %s\nExpected to contain:\n%s\nActual:\n%s\n' "$1" "$2" "$3" >&2
    failures=$((failures + 1))
  fi
}

# @param $1 description
# @param $2 text the output must not contain
# @param $3 actual output
expect_no_text() {
  if [[ $3 != *"$2"* ]]; then
    printf 'ok:   %s\n' "$1"
  else
    printf 'FAIL: %s\nExpected not to contain:\n%s\nActual:\n%s\n' "$1" "$2" "$3" >&2
    failures=$((failures + 1))
  fi
}

offline="$(STUB_CURL_EXIT=6 run_superfile)"
expect_text 'a failed download warns' 'Could not download the superfile install script' "$offline"
expect_no_text 'a failed download is not reported as installed' 'superfile installed.' "$offline"

empty="$(STUB_CURL_EXIT=0 run_superfile)"
expect_text 'an empty download warns' 'Could not download the superfile install script' "$empty"

fetched="$(STUB_SCRIPT='sudo true || echo sudo-refused' run_superfile)"
expect_text 'the fetched script runs with sudo stubbed out' 'sudo-refused' "$fetched"
expect_text 'a script that exits 0 is reported as installed' 'superfile installed.' "$fetched"

failed="$(STUB_SCRIPT='exit 3' run_superfile)"
expect_text 'a script that fails warns' 'superfile install failed' "$failed"

complete="$(build_asset complete pay-respects _pay-respects-module-100-runtime-rules _pay-respects-fallback-100-request-ai man/pay-respects.1)"
out="$(run_pay_respects home-complete "$complete" "$(sha256_of "$complete")")"
expect_text 'a complete asset is reported as installed' 'pay-respects 0.8.8 installed.' "$out"
if [ -x "$tmp_dir/home-complete/.local/bin/pay-respects" ] \
  && [ -x "$tmp_dir/home-complete/.local/bin/_pay-respects-module-100-runtime-rules" ] \
  && [ ! -e "$tmp_dir/home-complete/.local/bin/_pay-respects-fallback-100-request-ai" ]; then
  echo 'ok:   the binary and rules module are copied, the AI fallback is not'
else
  echo 'FAIL: expected pay-respects and the rules module in ~/.local/bin, without the AI fallback' >&2
  failures=$((failures + 1))
fi

no_module="$(build_asset no-module pay-respects man/pay-respects.1)"
out="$(run_pay_respects home-no-module "$no_module" "$(sha256_of "$no_module")")"
expect_text 'an asset missing the rules module warns' "couldn't be copied into ~/.local/bin" "$out"
expect_no_text 'an asset missing the rules module is not reported as installed' 'installed.' "$out"
# A copied pay-respects passes the version check, and the next run would skip.
if [ ! -e "$tmp_dir/home-no-module/.local/bin/pay-respects" ]; then
  echo 'ok:   a failed module copy leaves no pay-respects for the next run to skip on'
else
  echo 'FAIL: a failed module copy left pay-respects in ~/.local/bin' >&2
  failures=$((failures + 1))
fi

out="$(run_pay_respects home-bad-sum "$complete" "$(printf '0%.0s' {1..64})")"
expect_text 'a bad checksum warns' 'pay-respects install failed' "$out"
expect_no_text 'a bad checksum is not reported as installed' 'installed.' "$out"

echo
if [ "$failures" -eq 0 ]; then
  echo "all checks passed"
fi
exit "$((failures > 0))"
