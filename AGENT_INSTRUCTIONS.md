# Agent playbook: flash Lenovo YT-K606F to official Android 13 (ROW)

Audience: an AI coding agent (Claude Code, etc.) with shell access on a **Windows 10/11** PC, a human operator next to the tablet.
Proven on a real device on 2026-09-23 (CN hardware, seller firmware `S200021_210415_ROW` → `S510234_231224_ROW`).

## Ground rules (non-negotiable)

1. **Every write to the device requires explicit human approval** in the chat for that specific step (fpinfo write, flash).
   Reads (adb getprop, GPT/partition dumps) are fine without asking.
2. **Back up before any write**: GPT of all 6 LUNs + `persist`, `fpinfo`, `frp`, `keystore`, `misc`, `ssd`, `lenovocust`,
   `lenovoraw`, `cdt`, `ddr`, `devinfo`, `secdata`, `modemst1`, `modemst2`, `fsg`, `fsc`. Record SHA-256.
3. **Never** send `provision_*.xml` (UFS provisioning — can permanently brick storage).
4. **Never** flash a package for a different model, and never flash CN ZUI on a unit you don't intend to keep CN.
5. **Never** publish backups: `fpinfo`/`persist` contain the serial number, Wi-Fi/BT MACs and calibration.
6. Keep a journal (what was run, when, result) in the working folder.
7. If anything in the checks below does not match — **stop and ask the human**.

## Paths used below

```
$Work = 'D:\yt-k606f'              # any folder with ~15 GB free
$Fw   = "$Work\firmware\S510234"   # unzipped firmware
$Qpst = 'C:\Program Files (x86)\Qualcomm\QPST\bin'
$Adb  = "$Work\platform-tools\adb.exe"
```

Use **PowerShell** for everything touching COM ports. Git-Bash/MSYS mangles `\\.\COM4` into `\.\COM4` → "Could not connect".

## Step 0 — Identify the device (read-only)

Ask the human to enable Developer options → USB debugging and accept the RSA prompt ("Always allow").

```powershell
& $Adb devices -l
& $Adb shell getprop | Select-String 'ro.build.display.id|ro.build.version.release|ro.product.name|ro.boot.countrycode|odm.tblenovo.countrycode|ro.odm.lenovo.region|ro.odm.lenovo.sku|ro.boot.flash.locked|ro.boot.slot_suffix|ro.build.version.security_patch'
& $Adb shell dumpsys battery | Select-String 'level|powered'
```

Interpretation:
- `ro.product.name=LenovoYT-K606F_PRC`, `ro.boot.countrycode=CNXX` → **CN hardware**.
- `ro.build.display.id=YT-K606F_S200021_210415_ROW` → seller's fake-global Android 11 (typical Ozon/AliExpress unit).
- Battery must be **≥ 50 %** (charge it; EDL does not charge reliably).

Save full `getprop` and `ls -l /dev/block/by-name/` to the journal folder.

**Do NOT** run Lenovo Software Fix / Rescue and Smart Assistant on CN hardware before checking the region byte —
documented bricks (Reddit r/Lenovo 1ia5n7l, exactly `S200021`).

## Step 1 — Tools

1. platform-tools: https://dl.google.com/android/repository/platform-tools-latest-windows.zip
2. QPST 2.7.496: https://media.qpsttool.com/wp-content/uploads/QPST_2.7.496.zip
   - Verify `QPST.2.7.496.1.exe` Authenticode: signer must be `CN="Qualcomm Technologies, Inc."`, status `Valid`.
   - Install with defaults (human clicks through UAC). Provides `QFIL.exe`, `QSaharaServer.exe`, `fh_loader.exe`.
3. **Qualcomm 9008 driver — use WHQL from Microsoft Update Catalog**, not the 2014 "QDLoader HS-USB Driver_64bit_Setup.exe":
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\install_qualcomm_whql_driver.ps1   # elevates, human confirms UAC
   ```
   The script downloads the catalog CAB (v2.1.1.0, `USB\VID_05C6&PID_9008`), verifies the catalog signature
   (`Microsoft Windows Hardware Compatibility Publisher`), removes old Qualcomm 2014 packages and installs `qcser.inf`.
   Symptom that you have the broken driver: `sc query qcusbser` → STOPPED, exit 1077; CodeIntegrity event 3004 for `qcusbser.sys`.
4. Make sure the PC won't sleep during flashing: `powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE` → AC index `0x0`.

## Step 2 — Firmware

Recommended: `YT-K606F_S510234_231224_ROW.zip` (Android 13), see `LINKS.md` for URL + SHA-256.

```powershell
curl.exe -L -C - -o "$Work\firmware\YT-K606F_S510234_231224_ROW.zip" https://mirrors-obs-1.lolinet.com/firmware/lenowow/2021/Yoga_Tab_13/YT-K606F/YT-K606F_S510234_231224_ROW.zip
(Get-FileHash "$Work\firmware\YT-K606F_S510234_231224_ROW.zip").Hash   # compare with LINKS.md
Expand-Archive ... -DestinationPath $Fw       # or 7-Zip / unzip; ~6.5 GB, 87 files
powershell -File scripts\verify_firmware.ps1 -FirmwareDir $Fw
```

Note: `mirrors.lolinet.com/firmware/lenowow/2021/...` returns 404 — 2021 models moved to `mirrors-obs-1.lolinet.com`.

`verify_firmware.ps1` must report: build `YT-K606F_S510234_231224_ROW`, release `13`, SKU `bladex_row_wifi`, every file referenced
by `rawprogram*.xml` present, all `SECTOR_SIZE_IN_BYTES="4096"`, and which labels will be written.

If using `S510488_240910_ROW`: rename every `*.x` to `*.xml` first (contents.x, rawprogram*.x, patch*.x, provision_*.x).

## Step 3 — Enter EDL and load firehose (RAM only, no writes)

```powershell
powershell -File scripts\edl_enter_and_sahara.ps1 -Programmer "$Fw\prog_firehose_ddr.elf"
```

- Uses `adb reboot edl` (works on this model with a locked bootloader); fallback: power off → hold **Vol+** → plug USB.
- The PBL stays in EDL only briefly without a Sahara host — the script uploads the programmer immediately.
- Success: `File transferred successfully` / `Sahara protocol completed`. Port name is printed (`PORT=COMx`).
- Sahara accepting the programmer also proves the package is signed with the OEM key your SoC trusts.

Sanity check (read-only):
```powershell
& "$Qpst\fh_loader.exe" --port=\\.\COM4 --getstorageinfo=0 --memoryname=ufs --noprompt --zlpawarehost=1
```
Expect `"mem_type":"UFS"`, `"block_size":4096`, `num_physical: 6`.

## Step 4 — Read-only backups

```powershell
powershell -File scripts\backup_partitions.ps1 -Port COM4 -OutDir "$Work\backups"
python scripts\gpt_compare.py --device "$Work\backups\gpt" --package $Fw
```

`gpt_compare.py` must print **only one** difference: LUN0 `userdata` end LBA (the package holds a placeholder that
`patch0.xml` rewrites to `NUM_DISK_SECTORS-6`). Any other difference → STOP.

Key LUN0 offsets observed (4096-byte sectors): `persist` 8+8192, `frp` 8584+128, `fpinfo` 8712+256.
`frp` (Factory Reset Protection) and `fpinfo` are different partitions — don't mix them up.

## Step 5 — Region byte (fpinfo)

```powershell
python scripts\fpinfo_inspect.py "$Work\backups\partitions\fpinfo.bin"
```

| byte `0xE9` | meaning | action |
|---|---|---|
| `00` | region unbound (seller already patched) | flash ROW directly — no write needed |
| `01` | ROW | flash ROW directly |
| `02` | CN / ZUI | **patch to `01` before flashing ROW** (needs human approval) |

Patching (only if `02`):
```powershell
python scripts\fpinfo_inspect.py "$Work\backups\partitions\fpinfo.bin" --set-region 01 --out "$Work\fpinfo_row.bin"   # writes a copy, verifies 1-byte diff
powershell -File scripts\write_fpinfo.ps1 -Port COM4 -Image "$Work\fpinfo_row.bin" -Layout "$Work\backups\gpt\device_layout.json"
```
`write_fpinfo.ps1` writes, reads back and compares SHA-256.
Do not change anything else in `fpinfo` (country code `CNXX`, serial, MACs stay as is).

## Step 6 — Flash (requires explicit human approval)

Before asking, present: build/version, what is written vs. preserved, backups done, battery %, expected duration.

```powershell
powershell -File scripts\flash_firmware.ps1 -Port COM4 -FirmwareDir $Fw
```

Equivalent to QFIL Flat Build + UFS: `fh_loader --sendxml=rawprogram_unsparse0.xml,rawprogram1..5.xml,patch0..5.xml --memoryname=ufs --setactivepartition=1 --reset`.
Expected: `{All Finished Successfully}`, ~175 s at ~39 MB/s, zero `ERROR`/`NAK` in the log. The tablet reboots itself.

What gets written: GPT (all LUNs), `xbl`/`xbl_config` (LUN1/2), both A/B slots of `abl aop tz hyp modem dsp bluetooth keymaster devcfg`
etc., `boot`, `dtbo`, `vbmeta`, `vbmeta_system`, `recovery`, `super`, `metadata`, `userdata` (**wipes user data**), `lenovocust`, `lenovoraw`.
Preserved (empty filename in rawprogram): `persist`, `fpinfo`, `frp`, `keystore`, `misc`, `ssd`, `modemst1/2`, `fsg`, `fsc`, `devinfo`, `secdata`, `cdt`, `ddr`.

## Step 7 — Verify

First boot: 5–10 min. After setup, re-enable USB debugging:
```powershell
& $Adb shell getprop ro.build.display.id   # YT-K606F_S510234_231224_ROW
& $Adb shell getprop ro.build.version.release  # 13
```
Optional later: Lenovo Software Fix / OTA → `S510488_240910_ROW` (last build; known charging-while-off complaints).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Failed to open com port handle`, port vanishes after seconds | Broken 2014 driver blocked by Code Integrity → Step 1.3 WHQL driver. Also: bash path mangling → use PowerShell. Also close QPST Server/QFIL holding the port. |
| Sahara fail in QFIL | driver/admin rights; QFIL storage type must be **UFS** (default eMMC fails). Reinstall QPST, run as admin. |
| Black screen "hardware/software incompatible" after flashing ROW | region byte `02` → Step 5, reflash. EDL (PBL in ROM) is still reachable. |
| `contents.xml` missing (S510488) | files named `*.x` → rename to `*.xml`. |
| Not charging while powered off (S510488) | known on the last build; S510234 doesn't have it. |
| Serial number lost | `persist` erased (seen on ROW→CN). Restore your own `persist` backup. |
| FRP after flash | QFIL doesn't clear FRP; sign in with the previous Google account. |
