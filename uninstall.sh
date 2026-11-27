#!/system/bin/sh
# Cleanup on uninstall (Magisk removes $MODDIR automatically)
umount /apex/com.android.bt/lib64/libbluetooth_jni.so 2>/dev/null || true
for d in /apex/com.android.bt@*; do
    umount "$d/lib64/libbluetooth_jni.so" 2>/dev/null || true
done
