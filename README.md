# Android 17 Universal LHDC V5 Enabler (Magisk)

A universal **Magisk** module for **Android 17 (SDK 37) ARM64** custom ROMs that enables native **LHDC V5** Bluetooth audio encoding up to **192 kHz / 24-bit** and **1000 kbps** using AOSP's built-in Rust LHDC V5 software encoder (`lhdcv5BT_enc`) — no device-specific binary blobs included.

## Why this is needed
On many Android 17 custom ROMs (LineageOS, Infinity-X, crDroid, etc.), the Bluetooth stack (`/apex/com.android.bt/lib64/libbluetooth_jni.so`) already ships AOSP's Rust LHDC V5 software encoder, **but**:
1. `A2dpCodecs::init()` explicitly disables `LHDCv5` (`"LHDCv5 codec disabled"`).
2. `A2dpCodecConfigLhdcV5::setCodecConfig()` defaults to `48 kHz` and `ABR` (`400 kbps`) even when the earbuds support `192 kHz` and `1000 kbps`.
3. The vendor Bluetooth Audio AIDL HAL (`libbluetooth_audio_session_aidl.so`) caps `GetSoftwarePcmCapabilities()` at `96 kHz`, causing `AudioPolicyManager` to reject `192 kHz` software PCM streams and fall back to the phone speaker.

## Features
- **Dynamic binary patching at install time:** Patches your own device's `libbluetooth_jni.so` and `libbluetooth_audio_session_aidl.so` (32-bit & 64-bit) using ARM64/rodata pattern matching — works across devices and ROM updates.
- **192 kHz / 24-bit by default:** Prefers `192 kHz` when supported by your earbuds, with automatic fallback to `96 / 48 / 44.1 kHz` on earbuds that don't support `192 kHz`.
- **Default 500 kbps (`LHDC_QUALITY_MID`):** Smooth, stutter-free playback by default, even on mid-range SoCs (e.g., Snapdragon 665).
- **1-Tap Bitrate Switcher:**
  - **Magisk Action button:** Tap **Action** on the module in Magisk to cycle `500 → 900 → 1000 → 500 kbps`.
  - **CLI / Home-screen shortcut (`lhdc-mode`):**
    ```sh
    su -c lhdc-mode 500    # 500 kbps (default, most stable)
    su -c lhdc-mode 900    # 900 kbps (high quality)
    su -c lhdc-mode 1000   # 1000 kbps (max quality)
    su -c lhdc-mode abr    # Adaptive bitrate (400-1000 kbps)
    su -c lhdc-mode next   # Cycle 500 -> 900 -> 1000
    ```

## Requirements
- Rooted **Android 17** (ARM64) device with **Magisk** (v27+ recommended for the Action button).
- **LHDC V5 compatible earbuds** (tested on **OnePlus Buds 4** on **Redmi Note 8 / `ginkgo`** running **Project Infinity-X 4.2**).
- If your ROM's `/vendor/etc/audio_policy_configuration.xml` does not include `AUDIO_FORMAT_LHDC` / `192000` on `BT A2DP Out`, pair this with an audio policy module such as `android17-lhdc-a2dp-universal`.

## Installation
1. Download `android17-lhdc-v5-universal-v1.0.0-magisk.zip` from Releases (or build it with `python build_zip.py`).
2. Flash in **Magisk → Modules → Install from storage**.
3. **Reboot** your device.
4. Connect your LHDC V5 earbuds and verify in **Developer Options → Bluetooth audio codec** (`LHDCv5`, `192.0 kHz`, `24 bits/sample`).

## Disclaimer
Use at your own risk. If Bluetooth ever fails to start after a ROM/APEX update, disable or remove the module in Magisk and reboot.
