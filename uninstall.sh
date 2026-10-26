#!/usr/bin/env bash
# Remove the Samsung legacy driver bits this repo installs.
# Leaves Icons/ and SCMS/ directories intact (they are shared Samsung-wide
# and other installed Samsung printers may need them).
#
# Usage:  sudo ./uninstall.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "run as root:  sudo $0" >&2
  exit 1
fi

DST_PRINTER_ROOT="/Library/Printers/Samsung"
DST_PPD_ROOT="/Library/Printers/PPDs/Contents/Resources"

echo "==> removing per-model folders"
rm -rf "$DST_PRINTER_ROOT/ML-1640" "$DST_PRINTER_ROOT/ML-1865W"

echo "==> removing shared QPDL filters"
rm -f "$DST_PRINTER_ROOT/UPD/Filters/rastertoqpdl" \
      "$DST_PRINTER_ROOT/UPD/Filters/pstoqpdl"

echo "==> removing PPDs"
rm -f "$DST_PPD_ROOT/Samsung ML-1640 Series.gz" \
      "$DST_PPD_ROOT/Samsung ML-1865W Series.gz" \
      "$DST_PPD_ROOT/Samsung ML-1865W.gz"

echo
echo "Done. Any CUPS queue you added for these printers is still there —"
echo "remove it from System Settings > Printers & Scanners if you want it gone."
