#!/system/bin/sh
MODDIR=${0%/*}
LIB="$MODDIR/files/libbluetooth_jni.so"
[ -f "$LIB" ] || exit 0

chmod 0644 "$LIB"
chown system:system "$LIB"
chcon u:object_r:system_lib_file:s0 "$LIB" 2>/dev/null || true

if [ -f /apex/com.android.bt/lib64/libbluetooth_jni.so ]; then
    mount -o bind "$LIB" /apex/com.android.bt/lib64/libbluetooth_jni.so 2>/dev/null || true
fi
for d in /apex/com.android.bt@*; do
    if [ -f "$d/lib64/libbluetooth_jni.so" ]; then
        mount -o bind "$LIB" "$d/lib64/libbluetooth_jni.so" 2>/dev/null || true
    fi
done
