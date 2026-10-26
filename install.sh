#!/usr/bin/env bash
# Samsung legacy printer driver installer for modern macOS (Ventura 13+ /
# Sonoma 14 / Sequoia 15 / macOS 26+), Intel and Apple Silicon.
#
# Supports: ML-1640, ML-1865W (QPDL / Samsung UPD rasterizer).
# Other QPDL-family models (ML/SCX series) will likely work too — drop the
# matching PPD into /Library/Printers/PPDs/Contents/Resources/ and reuse the
# shared filters this script sets up.
#
# Usage:  sudo ./install.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "run as root:  sudo $0" >&2
  exit 1
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DST_PRINTER_ROOT="/Library/Printers/Samsung"
DST_PPD_ROOT="/Library/Printers/PPDs/Contents/Resources"

echo "==> copying driver tree into $DST_PRINTER_ROOT (merging, not replacing)"
mkdir -p "$DST_PRINTER_ROOT"
# -R to recurse, no -n so updated filters/PPDs overwrite stale copies, but
# shared dirs like Icons/ and SCMS/ merge instead of blowing away other
# Samsung models the user may already have installed.
/bin/cp -R "$REPO_ROOT/Samsung/." "$DST_PRINTER_ROOT/"

echo "==> installing PPDs into $DST_PPD_ROOT"
mkdir -p "$DST_PPD_ROOT"
shopt -s nullglob
for ppd in "$REPO_ROOT"/*.gz; do
  install -m 755 -o root -g admin "$ppd" "$DST_PPD_ROOT/$(basename "$ppd")"
done
shopt -u nullglob

echo "==> fixing ownership and permissions"
chown -R root:admin "$DST_PRINTER_ROOT"
chmod -R u+rwX,go+rX "$DST_PRINTER_ROOT"
chmod 755 "$DST_PRINTER_ROOT/UPD/Filters/"*

echo "==> stripping Gatekeeper quarantine attribute"
xattr -dr com.apple.quarantine "$DST_PRINTER_ROOT" 2>/dev/null || true
for ppd in "$DST_PPD_ROOT"/Samsung\ *.gz; do
  xattr -d com.apple.quarantine "$ppd" 2>/dev/null || true
done

echo "==> ad-hoc code-signing CUPS filters (kills the 'developer cannot be verified' dialog)"
# The filters shipped by Samsung in 2010 are unsigned universal binaries
# (i386 + ppc_7400 + x86_64). An ad-hoc signature is enough to satisfy the
# post-Ventura Gatekeeper check for CUPS backends.
for f in "$DST_PRINTER_ROOT/UPD/Filters/"*; do
  codesign --force --sign - --deep "$f" 2>/dev/null \
    && echo "    signed $(basename "$f")" \
    || echo "    WARN: could not sign $(basename "$f")" >&2
done

if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  echo
  echo "!! Rosetta is NOT installed. These filters are x86_64; printing will"
  echo "   fail on Apple Silicon until you install Rosetta:"
  echo "       softwareupdate --install-rosetta --agree-to-license"
fi

echo
echo "Done. Next:"
echo "  1. Open System Settings > Printers & Scanners > Add Printer"
echo "  2. Pick your Samsung model (ML-1640 or ML-1865W) from the driver list"
echo "  3. Print a test page — no 'Allow Anyway' dance should be needed"
