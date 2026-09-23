# 📲 YOGATAB13.android13.FLASH

**Take a Lenovo Yoga Tab 13 (YT-K606F) from a dead-end Android 11 to official Android 13 without bricking it.**

Bought a Yoga Tab 13 / YOGA Pad Pro on Ozon Global or AliExpress? Chances are it's **Chinese hardware with a seller's
fake-global Android 11** (`S200021`, security patch from 2021) that never gets an OTA. Lenovo's own rescue tool
**bricks** exactly these units, the popular Qualcomm driver **doesn't even load on Windows 11**, and the forum guides
contradict each other about the region lock.

**YOGATAB13.android13.FLASH** is the tested, end-to-end procedure. It covers which firmware, which driver, where the
region byte lives, what the flash overwrites and what it keeps, and a playbook an AI agent can follow step by step.
All of it was proven on a real unit: **0 errors, Android 13 boots.**

![Device: YT-K606F](https://img.shields.io/badge/device-Lenovo%20YT--K606F-E2231A)
![Android 13](https://img.shields.io/badge/Android-13%20ROW-3DDC84)
![Tested 2026-09-23](https://img.shields.io/badge/tested-2026--09--23-brightgreen)
![Tool: QPST / EDL](https://img.shields.io/badge/tool-QPST%20%2F%20EDL%209008-5391FE)
![Windows 10/11](https://img.shields.io/badge/Windows-10%20%2F%2011-0078D6)
![Version v1.0.0](https://img.shields.io/badge/version-v1.0.0-purple)
![Language: EN / RU](https://img.shields.io/badge/language-EN%20%2F%20RU-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

---

## 🔥 Why you'll love it

| ❌ The trap | ✅ What this repo does |
|---|---|
| "Is there Android 14?" — forums say maybe | **No.** Lenovo officially cancelled A14 (2024-11-28), and no GSI has ever booted on K606F. **A13 ROW is the ceiling** |
| Lenovo Software Fix bricks CN units with `S200021` | Flashes over **EDL/firehose** with `fh_loader`, the same thing QFIL does, fully logged |
| Win11 blocks the 2014 Qualcomm 9008 driver → *"Failed to open com port handle"* | Installs the **WHQL driver from Microsoft Update Catalog**, signature-checked |
| Region lock: "change 02 to 01" — but where? and is it even 02? | Documents the **`fpinfo` byte `0xE9`**. Many seller units are already `00`, so check it and don't write blindly |
| Fear of losing serial number / Wi-Fi calibration | Proves the package **never touches** `persist`, `fpinfo`, `modemst`, `fsg`, `devinfo`, and backs them up anyway |
| Latest build `S510488` won't load in QFIL (`contents.x`) and won't charge when off | Recommends **`S510234_231224_ROW`** (A13, clean package), with SHA-256 |
| Dead links everywhere | Every link verified, with sizes and **SHA-256** in [`LINKS.md`](LINKS.md) |

## 🖥️ What it looks like

Real output from the tested run (serial masked):

```
PS> scripts\edl_enter_and_sahara.ps1 -Programmer firmware\S510234\prog_firehose_ddr.elf
adb reboot edl
EDL port: COM4
File transferred successfully · Sahara protocol completed

PS> python scripts\gpt_compare.py --device backups\gpt --package firmware\S510234
LUN0: device 18 / package 18 partitions, differences: 1
   DIFF (0, 'userdata', (1790760, 61933562), (1790760, 1790759))   <- placeholder, patched
LUN1..LUN5: differences: 0
RESULT: OK

PS> python scripts\fpinfo_inspect.py backups\partitions\fpinfo.bin
country code (0x00): CNXX
model        (0x14): LenovoYT-K606F_PRC
serial       (0xAA): 8SSP*******************
REGION       (0xE9): 00  -> unbound (00)        <- flash ROW directly

PS> scripts\flash_firmware.ps1 -Port COM4 -FirmwareDir firmware\S510234
Sending <setbootablestoragedrive>
{All Finished Successfully}
Overall to target 175.953 seconds (38.99 MBps)
ERROR/NAK lines: 0
```

## 🧭 The 9 steps

| # | Step | What happens | Script |
|---|---|---|---|
| 1 | **Identify** | `getprop`: CN hardware? seller build? battery ≥ 50 % | [AGENT_INSTRUCTIONS](AGENT_INSTRUCTIONS.md#step-0--identify-the-device-read-only) |
| 2 | **Driver** | Remove blocked 2014 Qualcomm packages, install WHQL 9008 v2.1.1.0 | [install_qualcomm_whql_driver.ps1](scripts/install_qualcomm_whql_driver.ps1) |
| 3 | **Firmware** | Download S510234, SHA-256, unzip, sanity-check the package | [verify_firmware.ps1](scripts/verify_firmware.ps1) |
| 4 | **EDL** | `adb reboot edl` → load firehose immediately (RAM only) | [edl_enter_and_sahara.ps1](scripts/edl_enter_and_sahara.ps1) |
| 5 | **Backup** | GPT of all 6 UFS LUNs + 16 unique partitions + SHA-256 (read-only) | [backup_partitions.ps1](scripts/backup_partitions.ps1) |
| 6 | **Compare** | Device GPT vs package GPT — only `userdata` end may differ | [gpt_compare.py](scripts/gpt_compare.py) |
| 7 | **Region** | `fpinfo` byte `0xE9`: `00`/`01` → go, `02` → patch to `01` | [fpinfo_inspect.py](scripts/fpinfo_inspect.py) · [write_fpinfo.ps1](scripts/write_fpinfo.ps1) |
| 8 | **Flash** | rawprogram* + patch*, bootable LUN 1, reset (~3 min) | [flash_firmware.ps1](scripts/flash_firmware.ps1) |
| 9 | **Verify** | First boot 5–10 min → `ro.build.display.id` = `S510234`, Android 13 | [AGENT_INSTRUCTIONS](AGENT_INSTRUCTIONS.md#step-7--verify) |

## ✨ Features

- **Agent-ready playbook**: [`AGENT_INSTRUCTIONS.md`](AGENT_INSTRUCTIONS.md) is written for Claude Code and similar agents.
  Reads are free, every write needs a human "yes", and there are hard stop conditions.
- **Read-only first**: backups, GPT comparison and region check all happen *before* anything is written.
- **Nothing blind**: firmware SHA-256, Authenticode/WHQL signature checks, 1-byte-diff guard on `fpinfo`, write-and-read-back verification.
- **Region-lock map**: the full [`fpinfo` layout](docs/fpinfo_layout.md), offset by offset.
- **Research, condensed**: 4PDA (1100+ posts), XDA, Lenovo forums, Reddit, zui.com, summed up in [`docs/research.md`](docs/research.md).
- **📺 Bonus, Xiaomi Mi Box remote**: Home and Mic buttons dead on the tablet? Fixed without root. Mic → **Gemini**.
  See [`docs/xiaomi_remote.md`](docs/xiaomi_remote.md).

## ⚡ Quick start

> Requirements: Windows 10/11, PowerShell, Python 3, ~15 GB free, USB cable, tablet charged ≥ 50 %.
> **Flashing wipes all data on the tablet.**

**Option A, let an agent do it:** open the repo in Claude Code and say *"follow AGENT_INSTRUCTIONS.md"*.

**Option B, by hand:** follow [`AGENT_INSTRUCTIONS.md`](AGENT_INSTRUCTIONS.md) step by step; every command is there.

```powershell
git clone https://github.com/dobrdigital/YOGATAB13.android13.FLASH
cd YOGATAB13.android13.FLASH
```

Downloads (firmware, QPST, driver, adb) with SHA-256 are in [`LINKS.md`](LINKS.md).

## 🔒 Safe & reversible

- EDL lives in the SoC's boot ROM, so a failed software flash can always be redone over 9008.
- The package **does not write** `persist`, `fpinfo`, `frp`, `modemst1/2`, `fsg`, `devinfo` (empty `filename` in `rawprogram`).
- `provision_*.xml` (UFS provisioning) is **never** sent.
- Your backups stay local. `.gitignore` blocks `*.bin`, `*.img`, `backups/`, and the issue template asks you not to paste serials/MACs.

## 📝 Report your result

Flashed your unit (or bricked it)? Open a [flash report](../../issues/new?template=flash_report.yml). Starting build,
region byte and outcome make this safer for the next person.

## 📄 License

[MIT](LICENSE). Firmware, QPST and drivers are not included and belong to Lenovo, Qualcomm, Microsoft and Google.
Flashing voids warranty and is at your own risk.

---

*Built with ❤ at **REAILISM.DEV** — because a flagship-class tablet deserves better than Android 11.*

---

<details>
<summary><b>🇷🇺 Русская документация</b></summary>

# 📲 YOGATAB13.android13.FLASH

**Как перевести Lenovo Yoga Tab 13 (YT-K606F) с тупикового Android 11 на официальный Android 13 и не окирпичить.**

Купили Yoga Tab 13 / YOGA Pad Pro на Ozon Global или AliExpress? Скорее всего, это **китайское железо с псевдоглобальной
прошивкой продавца на Android 11** (`S200021`, патч 2021 года), которая никогда не обновится. Фирменная утилита Lenovo
**окирпичивает** именно такие планшеты, популярный драйвер Qualcomm **не запускается на Windows 11**, а инструкции
на форумах противоречат друг другу насчёт региональной блокировки.

Здесь проверенная процедура целиком: какая прошивка, какой драйвер, где лежит байт региона, что прошивка
перезаписывает и что сохраняет, плюс инструкция, по которой ИИ-агент может пройти всё пошагово.
Проверено на живом планшете: **0 ошибок, Android 13 загружается.**

## Коротко

| Вопрос | Ответ |
|---|---|
| Максимальная версия | **Android 13**: ROW `S510234_231224` (рекомендуется) или `S510488_240910` (последняя, с багами) |
| Android 14+? | **Нет.** Lenovo официально отменила A14 (28.11.2024), GSI на K606F ни у кого не загрузился, TWRP/LineageOS нет |
| Китайская ZUI | Последняя — ZUI 14.0.494 (Android 12). ZUI 15 вышла для другого планшета (TB-J716F) |
| Чем шить | QPST 2.7.496 (`fh_loader` / QFIL) в режиме EDL 9008. Fastboot-прошивок нет |
| Главный риск | ROW на китайском железе с байтом региона `02` → «несовместимое железо». Проверьте `fpinfo`, байт `0xE9`: `00`/`01` — можно шить, `02` — сначала поменять на `01`. У продавцов часто уже `00` |
| Windows 11 | Драйвер 9008 2014 года блокируется (CodeIntegrity 3004) → «Failed to open com port handle». Ставьте **WHQL из Microsoft Update Catalog** |

## Как понять, что у вас (adb, только чтение)

```
adb shell getprop ro.product.name        # LenovoYT-K606F_PRC  => китайское железо
adb shell getprop ro.boot.countrycode    # CNXX                 => китайское железо
adb shell getprop ro.build.display.id    # YT-K606F_S200021_210415_ROW => псевдоглобалка продавца
```

## 9 шагов

1. **Диагностика** — `getprop`, батарея ≥ 50 %.
2. **Драйвер** — удалить заблокированный Qualcomm 2014, поставить WHQL 9008 ([скрипт](scripts/install_qualcomm_whql_driver.ps1)).
3. **Прошивка** — скачать S510234, сверить SHA-256, распаковать, проверить ([скрипт](scripts/verify_firmware.ps1)).
4. **EDL** — `adb reboot edl` и сразу загрузить firehose ([скрипт](scripts/edl_enter_and_sahara.ps1)).
5. **Бэкап** — GPT всех 6 LUN и 16 уникальных разделов, только чтение ([скрипт](scripts/backup_partitions.ps1)).
6. **Сверка** — GPT планшета и прошивки; отличаться может только конец `userdata` ([скрипт](scripts/gpt_compare.py)).
7. **Регион** — байт `0xE9` в `fpinfo` ([скрипт](scripts/fpinfo_inspect.py)).
8. **Прошивка** — rawprogram + patch, загрузочный LUN 1, перезагрузка, ~3 минуты ([скрипт](scripts/flash_firmware.ps1)).
9. **Проверка** — первый запуск 5–10 минут, затем `S510234`, Android 13.

Подробно, с командами: [`AGENT_INSTRUCTIONS.md`](AGENT_INSTRUCTIONS.md) (англ.). Ссылки и SHA-256: [`LINKS.md`](LINKS.md).

## Бонус: пульт Xiaomi Mi Box

Кнопки «Домой» и микрофон на планшете не работают: пульт шлёт их как клавиши ПК-клавиатуры (`MOVE_HOME` и `F5`).
Без root лечится приложением Key Mapper, микрофон запускает **Gemini** (нужен VPN в стране, где он доступен).
Подробно: [`docs/xiaomi_remote.md`](docs/xiaomi_remote.md).

## Безопасность

Прошивка **не трогает** `persist`, `fpinfo`, `frp`, `modemst1/2`, `fsg`, `devinfo`: серийник и калибровки сохраняются.
EDL находится в ПЗУ, поэтому неудачную прошивку всегда можно повторить. Прошивка **стирает все данные** и лишает гарантии.

Прошили или окирпичили? Оставьте [отчёт о прошивке](../../issues/new?template=flash_report.yml).

Лицензия: [MIT](LICENSE). Сделано в **REAILISM.DEV**.

</details>
