#!/system/bin/sh
MODDIR=${0%/*}
LIB="$MODDIR/files/libbluetooth_jni.so"
[ -f "$LIB" ] || exit 0

i=0
while [ $i -lt 30 ]; do
    ZPID=$(pidof zygote64)
    if [ -n "$ZPID" ] && [ -f /apex/com.android.bt/lib64/libbluetooth_jni.so ]; then
        break
    fi
    sleep 1
    i=$((i + 1))
done

chmod 0644 "$LIB"
chown system:system "$LIB"
chcon u:object_r:system_lib_file:s0 "$LIB" 2>/dev/null || true

MOUNTED=0
if ! grep -q "libbluetooth_jni.so" /proc/mounts 2>/dev/null; then
    mount -o bind "$LIB" /apex/com.android.bt/lib64/libbluetooth_jni.so 2>/dev/null || true
    for d in /apex/com.android.bt@*; do
        [ -f "$d/lib64/libbluetooth_jni.so" ] && mount -o bind "$LIB" "$d/lib64/libbluetooth_jni.so" 2>/dev/null || true
    done
    MOUNTED=1
fi

ZPID=$(pidof zygote64)
if [ -n "$ZPID" ]; then
    if ! nsenter -t "$ZPID" -m -- grep -q "libbluetooth_jni.so" /proc/mounts 2>/dev/null; then
        nsenter -t "$ZPID" -m -- mount -o bind "$LIB" /apex/com.android.bt/lib64/libbluetooth_jni.so 2>/dev/null || true
        for d in /apex/com.android.bt@*; do
            [ -f "$d/lib64/libbluetooth_jni.so" ] && nsenter -t "$ZPID" -m -- mount -o bind "$LIB" "$d/lib64/libbluetooth_jni.so" 2>/dev/null || true
        done
        MOUNTED=1
    fi
fi

if [ "$MOUNTED" = "1" ]; then
    BTPID=$(pidof com.android.bluetooth)
    if [ -n "$BTPID" ]; then
        killall com.android.bluetooth 2>/dev/null || true
    fi
fi
