# `fpinfo` partition (YT-K606F)

LUN0, 256 sectors × 4096 B (1 MiB); on the tested unit at LBA 8712. Not written by the firmware package.
Same layout as the TB-Q706F dump annotated on XDA ([screenshot](https://xdaforums.com/attachments/frpinfo-png.5703249/)).
Not to be confused with `frp` (Factory Reset Protection, the partition right before it).

| Offset | Size | Content | Example (masked) |
|---|---|---|---|
| `0x00` | 4 | Country code → `ro.boot.countrycode` | `CNXX` (CN unit), `USXX` |
| `0x0A` | 8 | GSN → `ro.odm.lenovo.gsn` | `HA1E****` |
| `0x14` | ~30 | Model / product name | `LenovoYT-K606F_PRC` |
| `0x32` | ~120 | Build fingerprint at manufacture / last provisioning | `Lenovo/LenovoYT-K606F_PRC/K606F:11/RKQ1.201217.002/S200021_210415_ROW:user/release-keys` |
| `0xAA` | 23 | Serial number (PSN) | `8SSP69A6P***************` |
| `0xC7` | 1 | Flag, `01` on both CN and ROW units (not the region) | `01` |
| `0xDB` | 6 | Wi-Fi MAC | `08:38:e6:**:**:**` |
| `0xE2` | 6 | Bluetooth MAC | `08:38:e6:**:**:**` |
| **`0xE9`** | **1** | **Region lock: `02` = CN/ZUI, `01` = ROW, `00` = unbound** | `00` on the tested seller unit |

Notes:
- Only `0xE9` is changed to move between CN and ROW. Leave the country code, serial and MACs alone.
- Units sold as "global" on Ozon/AliExpress with `S200021_210415_ROW` have been observed with `00`
  (tested unit; 4PDA [p=129240739](https://4pda.to/forum/index.php?showtopic=1034689&view=findpost&p=129240739)). ROW firmware then flashes and boots without any fpinfo change.
- One 4PDA post (p=113020232) states the codes the other way round. Always check your own dump against the table above
  (a CN-locked unit shows `02`) before writing.
- Never publish your dump: it contains serial number and MAC addresses.
