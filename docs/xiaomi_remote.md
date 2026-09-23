# Bonus: Xiaomi Mi Box Bluetooth remote on the tablet (Home + Mic buttons)

Pairing a Xiaomi Android TV box remote ("Xiaomi Remote", BLE) with the Yoga Tab 13 works out of the box for
D-pad, OK, Back and volume. **Home** and **Mic** do nothing. This was solved without root on 2026-09-23 (stock S510234, Android 13).

## Diagnosis (adb, read-only)

```sh
adb shell getevent -il | grep -A3 "Xiaomi Remote"      # -> /dev/input/eventN, vendor 0x2717 product 0x32b2
adb shell dumpsys input | grep -A12 "Xiaomi Remote"     # KeyLayoutFile: /system/usr/keylayout/Generic.kl (no vendor layout)
adb shell getevent -lt /dev/input/eventN                # press buttons one by one
```

| Button | HID usage | Linux key | Android keycode (Generic.kl) | Works? |
|---|---|---|---|---|
| OK | `0x070028` | `KEY_ENTER` | ENTER | yes |
| Back | `0x0700F1` | `KEY_BACK` | BACK | yes |
| Vol +/− | `0x070080` / `0x070081` | `KEY_VOLUMEUP/DOWN` | VOLUME_UP/DOWN | yes |
| **Home** | `0x07004A` (keyboard "Home") | `KEY_HOME` (102) | **MOVE_HOME (122)**: moves the text cursor, not "go home" | no |
| **Mic** | `0x07003E` (keyboard "F5") | `KEY_F5` (63) | **F5 (135)** | no |

Both buttons reach Android. They are just mapped as PC-keyboard keys. The remote's own microphone streams audio via Google's
ATV Voice (BLE) profile, which exists only on Android TV, so the remote's mic itself can't work on a tablet. The button can
still start a voice assistant that listens through the tablet's microphone.

## Fix: Key Mapper (no root)

1. Install [Key Mapper](https://github.com/keymapperorg/KeyMapper/releases) (tested: v4.5.0-foss, APK signing cert SHA-256
   `2f41a816b8d60aa1d7cd4976b4452b0335e583d4f4ab14071f303177850ce460`, same key as older GitHub releases; F-Droid builds use a
   different key, so don't mix the two sources). `adb install` avoids Android 13's "restricted setting" block for sideloaded accessibility apps.
2. Enable its accessibility service. In the UI: Settings → Accessibility → Key Mapper. Over adb, **append** to the existing list:
   ```sh
   adb shell settings get secure enabled_accessibility_services      # keep what's there
   adb shell settings put secure enabled_accessibility_services "<existing>:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
   ```
   Optional: `adb shell dumpsys deviceidle whitelist +io.github.sds100.keymapper` and
   `adb shell pm grant io.github.sds100.keymapper android.permission.POST_NOTIFICATIONS`.
3. Create two key maps. Record the trigger by pressing the real remote button, then open the key's options → Device = **Xiaomi Remote**, Short press:
   - `Home (Xiaomi Remote)` → action **Go home**
   - `F5 (Xiaomi Remote)` → action **Launch voice assistant** (opens Gemini / Google Assistant, whichever is the device assistant)

## Gemini on the mic button

- Install Google Gemini from Play. In regions where Gemini isn't offered it says "Gemini isn't available in this country". Use a VPN
  exiting in a supported country (Canada worked) that routes the **Google app** too (check split tunneling).
- The Google app caches the country: after switching VPN, force-stop it (`adb shell am force-stop com.google.android.googlequicksearchbox`
  or Settings → Apps → Google → Force stop) and reopen Gemini. Then accept the onboarding ("Use Gemini") on the device.

## Gotchas

- Force-stopping Key Mapper unbinds its accessibility service, and the remote buttons stop working. Re-enable it in Accessibility
  (or rewrite `enabled_accessibility_services`).
- `sendevent` to `/dev/input/eventN` is denied by SELinux even though `shell` is in the `input` group, so you can't simulate
  the remote. Trigger recording needs real button presses.
- `uiautomator dump` returns "null root node" while the screen is off. Wake it first (`input keyevent KEYCODE_WAKEUP`).
