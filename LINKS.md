# Links

Only what was actually used for the successful flash on 2026-09-23.
Forum pages are protected against bots (curl gets 403) but open in a normal browser.

## Downloads

| What | Link | Bytes | SHA-256 |
|---|---|---|---|
| Firmware `YT-K606F_S510234_231224_ROW` (Android 13) | https://mirrors-obs-1.lolinet.com/firmware/lenowow/2021/Yoga_Tab_13/YT-K606F/YT-K606F_S510234_231224_ROW.zip | 3365866684 | `b778389d3c6e88023956151d154b831b254cc8618504539af0119bcca1c29a0e` |
| Android platform-tools (adb) | https://dl.google.com/android/repository/platform-tools-latest-windows.zip | rolling | — |
| QPST 2.7.496 (QFIL, fh_loader, QSaharaServer) | https://media.qpsttool.com/wp-content/uploads/QPST_2.7.496.zip | 30788831 | `b0eecb317851fbff1a450fe0ee18be1faf59bc7744ff0e4383ed4c3f6f86a977` |
| Qualcomm QDLoader 9008 driver v2.1.1.0, **WHQL** (Microsoft Update Catalog) | https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2016/04/20855130_dae427ffe0a2d6268aa209d782d05ea874aad0dc.cab | 10042674 | `47b5301dce3e1639c10b8071b381227ce5237fa87973ff0282893d4e03e52fe5` |

| Key Mapper 4.5.0-foss (remote buttons, [docs](docs/xiaomi_remote.md)) | https://github.com/keymapperorg/KeyMapper/releases/download/v4.5.0/keymapper-4.5.0-foss.apk | 14943400 | `8927d7669bd9bd7c605797d7710886768aeb7a376d4cdd587a2b46d55a6be75e` |

Other builds for this model (incl. the last one, `S510488_240910_ROW`, and CN ZUI 14) are in the same mirror folder:
https://mirrors-obs-1.lolinet.com/firmware/lenowow/2021/Yoga_Tab_13/YT-K606F/

## Sources that decided the procedure

- **Region lock format**: XDA guide (TB-Q706F, same `fpinfo` layout) —
  https://xdaforums.com/t/tb-q706f-pad-pro-12-6-bypass-lenovos-region-lock-row-zui-easy.4487871/
  and its annotated hex dump showing byte `0xE9`: https://xdaforums.com/attachments/frpinfo-png.5703249/
- **Seller units already have region `00`, flash ROW directly** (4PDA, zhariks):
  https://4pda.to/forum/index.php?showtopic=1034689&view=findpost&p=129240739
- **CN→ROW step-by-step for K606F** when the byte is `02` (4PDA, marchcat07):
  https://4pda.to/forum/index.php?showtopic=1034689&view=findpost&p=132600778
- **Why Android 13 is the ceiling** — Lenovo: "Yoga Tab 13 will not get the Android 14 update":
  https://forums.lenovo.com/t5/Lenovo-Android-based-Tablets-and-Phablets/Android-14-not-available-for-my-Yoga-Tab-13/m-p/5346449
- **Why not to use Lenovo's rescue tool on these units** — brick with exactly `S200021`:
  https://www.reddit.com/r/Lenovo/comments/1ia5n7l/
