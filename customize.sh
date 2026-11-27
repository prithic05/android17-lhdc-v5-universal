#!/system/bin/sh
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

. "$MODPATH/lib/patch_elf.sh"

ui_print "**********************************************"
ui_print "        LHDC Enabler by Prithick"
ui_print "   Android 17 Universal LHDC V5 (192kHz)"
ui_print "**********************************************"

ARCH=$(getprop ro.product.cpu.abi)
case "$ARCH" in
    arm64*) ;;
    *) abort "! Unsupported architecture: $ARCH (ARM64 required)" ;;
esac

BT_JNI="/apex/com.android.bt/lib64/libbluetooth_jni.so"
if [ ! -f "$BT_JNI" ]; then
    abort "! $BT_JNI not found (requires Android 17 AOSP Bluetooth APEX)"
fi

mkdir -p "$MODPATH/files" "$MODPATH/system/bin" "$MODPATH/system/vendor/lib" "$MODPATH/system/vendor/lib64"

ui_print "- Patching Bluetooth stack (libbluetooth_jni.so)..."
if ! patch_bt_jni "$BT_JNI" "$MODPATH/files/libbluetooth_jni.so" "$MODPATH/quality_patch.conf"; then
    abort "! Failed to patch libbluetooth_jni.so"
fi

if [ -f /vendor/lib/libbluetooth_audio_session_aidl.so ]; then
    ui_print "- Patching 32-bit vendor BT Audio AIDL HAL..."
    patch_audio_aidl /vendor/lib/libbluetooth_audio_session_aidl.so "$MODPATH/system/vendor/lib/libbluetooth_audio_session_aidl.so"
fi

if [ -f /vendor/lib64/libbluetooth_audio_session_aidl.so ]; then
    ui_print "- Patching 64-bit vendor BT Audio AIDL HAL..."
    patch_audio_aidl /vendor/lib64/libbluetooth_audio_session_aidl.so "$MODPATH/system/vendor/lib64/libbluetooth_audio_session_aidl.so"
fi

echo "500" > "$MODPATH/current_mode"

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/system/bin/lhdc-mode" 0 0 0755
set_perm "$MODPATH/files/libbluetooth_jni.so" 0 0 0644
chcon u:object_r:system_lib_file:s0 "$MODPATH/files/libbluetooth_jni.so" 2>/dev/null || true

ui_print "- Default: LHDC V5 192kHz / 24-bit @ 500 kbps"
ui_print "- Tap Magisk Action button or run 'su -c lhdc-mode [500|900|1000|abr]'"
ui_print "- Reboot to activate!"
