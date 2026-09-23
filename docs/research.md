# Research summary (2026-09-23)

Sources: 4PDA thread (1100+ posts), XDA, Lenovo community, Reddit, zui.com / IT之家, firmware mirrors, GitHub.
Links: [`../LINKS.md`](../LINKS.md).

## Firmware ceiling
- Official path: Android 11 → 12 → **13** (ROW, June–July 2023). Last ROW build: `S510488_240910` (2024-09).
- **Android 14 cancelled**: Lenovo community moderator, 2024-11-28 — "the Lenovo Yoga Tab 13 will not get the Android 14 update".
- CN (ZUI): last release **ZUI 14.0.494** (Android 12, OTA6, May 2023). Lenovo CN (via XDA, 2023-07): "ZUI 14 is the final version".
  The ZUI 15 / Android 13 news of 2024 concerns the Xiaoxin Pad Pro 2021 (TB-J716F), not this model.
- Intermediate ROW A13 builds seen on mirrors: S510028_230614, S510043_230625, S510140_230926, S510234_231224, S510488_240910.

## Custom / Android 14+
- Bootloader unlock (`OEM unlocking` + `fastboot flashing unlock`) and Magisk (patched `boot.img`) reported on ROW A11/A12 (XDA 2022).
  No reports on A13. Unlocking drops Widevine L1 (streaming apps).
- **No report of any GSI (A13–A16) booting on K606F**; DSU with locked bootloader doesn't boot Google GSIs.
- No TWRP/OrangeFox/LineageOS builds; only WIP device trees (codename `bladex`, platform `kona`).
- 2026-05: one 4PDA user reports a mainline-ish kernel with Wi-Fi + HDMI-in working, audio not — experimental.

## CN ↔ ROW
- Region lock byte in `fpinfo` (see [`fpinfo_layout.md`](fpinfo_layout.md)). Confirmed working on K606F by several 4PDA users
  (2022-12, 2024-10, 2025-02, 2025-03); original method from XDA (TB-Q706F).
- Bricks come from: ROW on a `02` unit via Lenovo Rescue/LMSA ("device compromised" / "rom not compatible"), flashing another model's
  firmware, wiping `persist` (serial lost). None attributed to anti-rollback; QFIL downgrades A13→A11 reported working.
- Lenovo Rescue/Software Fix refuses "Chinese mainland" devices.

## Practical gotchas found while doing it
- Windows 11 blocks the 2014 Qualcomm driver (`qcusbser.sys`, CodeIntegrity 3004): port shows, can't be opened, EDL times out.
  WHQL v2.1.1.0 from Microsoft Update Catalog works.
- `adb reboot edl` works on this model (locked bootloader).
- Git Bash mangles `\\.\COMx`; run QPST CLI tools from PowerShell.
- Firmware package preserves `persist`, `fpinfo`, `frp`, `modemst*`, `fsg`, `devinfo`; GPT layout identical to the device
  except the `userdata` end placeholder patched by `patch0.xml`.
- Flash: ~6.8 GB in ~176 s over firehose at ~39 MB/s.
