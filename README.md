# LHDC Enabler by prithick (Android 17 Universal LHDC V5)

A universal **Magisk** module for **Android 17 (SDK 37, ARM64) only** that enables native **LHDC V5** Bluetooth audio encoding up to **192 kHz / 24-bit** and **1000 kbps** using AOSP's built-in Rust LHDC V5 software encoder (`lhdcv5BT_enc`).

> [!IMPORTANT]
> **Android 17 Only:** This module is built specifically for **Android 17 (SDK 37, ARM64)** custom ROMs using the AOSP Bluetooth APEX (`/apex/com.android.bt/lib64/libbluetooth_jni.so`). It will not work on Android 16 or earlier.

## Tested Device & ROM
- **Device:** Xiaomi Redmi Note 8 (`ginkgo`, Snapdragon 665)
- **ROM:** Project Infinity-X 4.2 (**Android 17**, SDK 37) — LHDC V5 was disabled by default in the ROM's Bluetooth stack (`LHDCv5 codec disabled`)
- **Earbuds:** OnePlus Buds 4
- **Root:** Magisk 31.1

## Why This Is Needed
On Android 17 custom ROMs, `/apex/com.android.bt/lib64/libbluetooth_jni.so` already includes AOSP's Rust LHDC V5 software encoder, **but**:
1. `A2dpCodecs::init()` explicitly disables `LHDCv5` (`"LHDCv5 codec disabled"`).
2. `A2dpCodecConfigLhdcV5::setCodecConfig()` defaults to `48 kHz` and `ABR` (`400 kbps`) even when the earbuds support `192 kHz` and `1000 kbps`.
3. The vendor Bluetooth Audio AIDL HAL (`libbluetooth_audio_session_aidl.so`) caps `GetSoftwarePcmCapabilities()` at `96 kHz`, causing `AudioPolicyManager` to reject `192 kHz` software PCM streams and fall back to the phone speaker.

## Features
- **Dynamic binary patching at install time (no device blobs):** Patches your own device's `libbluetooth_jni.so` and `libbluetooth_audio_session_aidl.so` (32-bit & 64-bit) using ARM64/rodata pattern matching.
- **192 kHz / 24-bit by default:** Prefers `192 kHz` when supported by your earbuds, with automatic fallback to `96 / 48 / 44.1 kHz`.
- **Default 500 kbps (`LHDC_QUALITY_MID`):** Smooth, stutter-free playback by default, even on mid-range SoCs.
- **1-Tap Bitrate Switcher:** Use the **Magisk Action button** or `lhdc-mode` CLI to switch between `500`, `900`, `1000`, and `abr`.

## Installation
1. Download `android17-lhdc-v5-universal-v1.0.0-magisk.zip` from [Releases](https://github.com/prithic05/android17-lhdc-v5-universal/releases) (or build it with `python build_zip.py`).
2. Open **Magisk → Modules → Install from storage** and select the ZIP.
3. **Reboot** your phone.
4. *(If your ROM's `/vendor/etc/audio_policy_configuration.xml` does not declare `AUDIO_FORMAT_LHDC` / `192000` on `BT A2DP Out`, pair this with an audio policy module such as `android17-lhdc-a2dp-universal`.)*

## Bitrate Switching Commands (On Phone)
- **Magisk App:** Go to **Modules → LHDC V5 192kHz Enabler → Action** to cycle `500 → 900 → 1000 → 500 kbps`.
- **Terminal / Termux:Widget / Shortcut Maker:**
  ```sh
  su -c lhdc-mode 500    # 500 kbps (default, most stable)
  su -c lhdc-mode 900    # 900 kbps (high quality)
  su -c lhdc-mode 1000   # 1000 kbps (max quality)
  su -c lhdc-mode abr    # Adaptive bitrate (400-1000 kbps)
  su -c lhdc-mode next   # Cycle 500 -> 900 -> 1000
  su -c lhdc-mode        # Show current mode
  ```

## Verification Commands (ADB / Windows)
Check negotiated codec, sample rate, bit depth, and active LHDC V5 bitrate from Windows PowerShell/CMD:
```sh
adb shell "dumpsys bluetooth_manager | grep -i -E 'Current Codec|mCodecConfig|mCodecsSelectableCapabilities|LHDC'"
```
Check encoder & audio HAL session logs:
```sh
adb shell "su -c 'logcat -b all -d | grep -i -E \"lhdcv5|StartSession|openOutput.*A2DP\" | tail -n 30'"
```

## License
Licensed under the [MIT License](LICENSE) — Copyright (c) 2026 **prithick**.

## Disclaimer
Use at your own risk. If Bluetooth ever fails to start after a ROM or APEX update, disable or remove the module in Magisk and reboot.
