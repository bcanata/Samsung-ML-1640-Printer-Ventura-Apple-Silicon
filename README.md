# Samsung ML-1640 & ML-1865W printer driver for modern macOS

Working driver install for Samsung legacy mono laser printers on **macOS
Ventura 13, Sonoma 14, Sequoia 15 and macOS 26+**, on both **Intel and Apple
Silicon**. Samsung stopped shipping drivers after HP took over in 2017 and the
official package no longer installs on anything past Big Sur, so these
printers are declared "unsupported" by every modern Mac. This repo revives
them.

Confirmed working:

| Model          | Connection | Tested on      |
|----------------|------------|----------------|
| ML-1640        | USB        | Ventura, Apple Silicon (original repo by [@MTz12](https://github.com/MTz12)) |
| ML-1865W       | Wi-Fi / Ethernet (`socket://…:9100`) | macOS 26, Apple Silicon |

Other Samsung models that use the **QPDL / SPL** rasterizer (ML-191x, ML-19x0,
ML-2160, ML-2240, ML-2525, SCX-3200, SCX-3400, SCX-4300…) will very likely
work too — the two filter binaries (`rastertoqpdl`, `pstoqpdl`) are shared
across the whole family. Drop the matching Samsung PPD into
`/Library/Printers/PPDs/Contents/Resources/` and the installer sets the rest
up for you.

## Install

```sh
git clone https://github.com/bcanata/Samsung-ML-1640-Printer-Ventura-Apple-Silicon.git
cd Samsung-ML-1640-Printer-Ventura-Apple-Silicon
sudo ./install.sh
```

Then open **System Settings → Printers & Scanners → Add Printer**, pick your
Samsung model from the driver list, and print.

The installer:

1. Merges the `Samsung/` tree into `/Library/Printers/Samsung/` (does **not**
   overwrite shared `Icons/` and `SCMS/` folders — other Samsung printers
   stay intact).
2. Copies the PPD files into `/Library/Printers/PPDs/Contents/Resources/`.
3. Fixes ownership (`root:admin`), permissions (`755`), and strips the
   `com.apple.quarantine` extended attribute.
4. **Ad-hoc code-signs the CUPS filters** (`codesign --sign -`). This is
   what kills the *"rastertoqpdl cannot be opened because the developer
   cannot be verified"* dialog for good — the original Samsung binaries from
   2010 are unsigned, and post-Ventura Gatekeeper refuses to run them until
   you either click through the Privacy & Security panel or sign them
   locally. The script does the latter, once, so you never see the dialog.

### Apple Silicon caveat

The filter binaries are universal **i386 + ppc_7400 + x86_64** — there is
no `arm64` slice. On Apple Silicon they run through Rosetta. If Rosetta is
not installed, the installer tells you and you can add it with:

```sh
softwareupdate --install-rosetta --agree-to-license
```

## Uninstall

```sh
sudo ./uninstall.sh
```

Removes the per-model folders, the shared QPDL filters, and the PPDs. The
CUPS print queue stays where it is — delete it from Printers & Scanners if
you want.

## What's actually in the box

```
Samsung ML-1640 Series.gz        PPD for ML-1640
Samsung ML-1865W Series.gz       PPD for ML-1865W
Samsung/
├── ML-1640/                     per-model autosetup + icon + Version.plist
├── ML-1865W/                    per-model icon + Version.plist
├── Icons/ML-1865W.icns          shared icons dir
├── SCMS/ml-1865Wsc.cts          Samsung Color Management strip for 1865W
└── UPD/Filters/
    ├── rastertoqpdl             CUPS raster -> QPDL converter
    └── pstoqpdl                 PostScript -> QPDL converter
install.sh / uninstall.sh
```

## Troubleshooting

- **"The Printer software was installed incorrectly."** when adding a
  printer: click **Repair**. Harmless, happens because the autosetupinfo
  isn't a full Apple-signed bundle. Doesn't affect printing.
- **Jobs sit forever as "Processing"** / nothing comes out: check CUPS logs
  with `tail -f /var/log/cups/error_log`. On Apple Silicon the usual cause is
  missing Rosetta; see above.
- **Still gets the "rastertoqpdl cannot be opened" dialog**: the ad-hoc
  signature may have been stripped. Re-run `sudo ./install.sh`.
- **AirPrint / IPP Everywhere?** Neither of these printers advertises PWG
  Raster, PDF or PCL in its IPP capabilities (`pdl=application/octet-stream`,
  `CMD=GDI`), so sadly no — this driver is the only path.

## Credits

Based on the original [MTz12/Samsung-ML-1640-Printer-Ventura-Apple-Silicon](https://github.com/MTz12/Samsung-ML-1640-Printer-Ventura-Apple-Silicon).
Thanks to Samsung's 2010 open-source filter binaries that still work 15 years
later.

## License

The Samsung-authored binaries and PPDs are redistributed under their original
Samsung terms; the installer scripts and docs in this fork are MIT.
