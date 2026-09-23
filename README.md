# Lenovo Yoga Tab 13 (YT-K606F) — flashing guide & agent playbook

Flash the **latest official Android 13 (ROW / global)** firmware onto a Lenovo Yoga Tab 13 **YT-K606F**
(Chinese name: YOGA Pad Pro 13"), including the very common case of a **Chinese-hardware unit sold as "global"**
(e.g. via Ozon Global / AliExpress) stuck on Android 11 with no OTA updates.

Tested end-to-end on 2026-09-23 on a real device: CN hardware running the seller's `YT-K606F_S200021_210415_ROW`
(Android 11, security patch 2021-03) → flashed `YT-K606F_S510234_231224_ROW` (Android 13). 0 errors, boots fine.

- **For AI agents:** follow [`AGENT_INSTRUCTIONS.md`](AGENT_INSTRUCTIONS.md) — a step-by-step procedure with safety gates.
- **All download links, sizes and SHA-256:** [`LINKS.md`](LINKS.md)
- **`fpinfo` region-lock partition format:** [`docs/fpinfo_layout.md`](docs/fpinfo_layout.md)
- **Research notes and sources:** [`docs/research.md`](docs/research.md)
- **Bonus: Xiaomi Mi Box BT remote on the tablet, fixing the Home + Mic (Gemini) buttons:** [`docs/xiaomi_remote.md`](docs/xiaomi_remote.md)
- **Scripts:** [`scripts/`](scripts)

## TL;DR

| Question | Answer |
|---|---|
| Newest firmware possible | **Android 13** — ROW `S510488_240910` (last) or `S510234_231224` (recommended). |
| Android 14+? | **No.** Lenovo officially cancelled A14 for Yoga Tab 13 (Lenovo forum, 2024-11-28). No GSI (A13–A16) has ever been reported booting on K606F; no TWRP/LineageOS. |
| Chinese ZUI | Final CN release is ZUI 14.0.494 (Android 12). ZUI 15 was released for the Xiaoxin Pad Pro 2021 (TB-J716F), not this model. |
| Recommended build | `YT-K606F_S510234_231224_ROW` — normal `contents.xml`; no charging bug. `S510488` ships its XMLs as `*.x` and users report it won't charge while powered off. |
| Tool | QPST 2.7.496 (QFIL / `fh_loader` / `QSaharaServer`) in EDL (9008) mode. **No fastboot packages exist.** |
| Biggest brick risk | ROW firmware on CN hardware whose region byte is `02` → "hardware incompatible" black screen. Fix **before** flashing: `fpinfo` byte `0xE9` `02`→`01`. Many "global" units already have `00` (unlocked by seller) — check first, don't write blindly. |
| Windows 11 gotcha | The popular 2014 "Qualcomm QDLoader 9008" installer is **blocked by Code Integrity** (event 3004) → COM port appears but can't be opened → "Failed to open com port handle" and the device drops out of EDL. Use the **WHQL driver from the Microsoft Update Catalog**. |

## Identify your unit (adb, read-only)

```
adb shell getprop ro.product.name        # LenovoYT-K606F_PRC  => CN hardware
adb shell getprop ro.boot.countrycode    # CNXX                 => CN hardware
adb shell getprop ro.build.display.id    # e.g. YT-K606F_S200021_210415_ROW (seller's fake-global A11)
```

`ro.boot.countrycode` comes from the first 4 bytes of the `fpinfo` partition. The *region lock* is a separate byte (see docs).

## Procedure overview

1. Install platform-tools, QPST 2.7.496, **WHQL** Qualcomm 9008 driver (`scripts/install_qualcomm_whql_driver.ps1`).
2. Download firmware, verify SHA-256, unzip, run `scripts/verify_firmware.ps1`.
3. `adb reboot edl` (or: power off → hold **Vol+** → plug USB) → `QDLoader 9008 (COMx)`.
4. Load firehose immediately: `scripts/edl_enter_and_sahara.ps1`.
5. **Read-only**: dump GPT of all 6 LUNs + back up unique partitions (`persist`, `fpinfo`, `modemst1/2`, `fsg`, …).
6. Compare device GPT with the package GPT (`scripts/gpt_compare.py`) — must be identical except `userdata` end.
7. Inspect `fpinfo` region byte (`scripts/fpinfo_inspect.py`): `00`/`01` → go; `02` → patch to `01` first.
8. Flash: `scripts/flash_firmware.ps1` (rawprogram* + patch*, bootable LUN 1, reset). ~3 min at ~39 MB/s.
9. First boot takes 5–10 min.

The firmware package **does not** write `persist`, `fpinfo`, `frp`, `modemst1/2`, `fsg`, `devinfo` (empty `filename` in `rawprogram`), so calibration, serial number and region byte survive the flash.

## Disclaimer

Flashing can brick your device and voids warranty. You do this at your own risk. This repository contains no firmware and no
device-specific data; firmware belongs to Lenovo and is linked from public mirrors.
