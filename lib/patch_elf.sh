#!/system/bin/sh
# Dynamic binary patcher for Android 17 LHDC V5 (ARM64)

BB="/data/adb/magisk/busybox"
[ -x "$BB" ] || BB=""

run_od() {
    if [ -n "$BB" ]; then
        "$BB" od -An -tx4 -w4 -v "$1"
    else
        od -An -tx4 -w4 -v "$1"
    fi
}

patch_4bytes_le() {
    # $1=file, $2=decimal_offset, $3=uint32_hex (e.g. d503201f)
    local file="$1" off="$2" hex="$3"
    local b0 b1 b2 b3
    b3=$(echo "$hex" | cut -c1-2)
    b2=$(echo "$hex" | cut -c3-4)
    b1=$(echo "$hex" | cut -c5-6)
    b0=$(echo "$hex" | cut -c7-8)
    printf "\\x${b0}\\x${b1}\\x${b2}\\x${b3}" | dd of="$file" bs=1 seek="$off" count=4 conv=notrunc 2>/dev/null
}

patch_bt_jni() {
    local src="$1" dst="$2" conf="$3"
    cp "$src" "$dst" || return 1

    # Scan 32-bit words with awk (0-indexed word index)
    local res
    res=$(run_od "$dst" | awk '
    function hex2dec(h,   i, c, v) {
        v = 0
        for (i = 1; i <= length(h); i++) {
            c = substr(h, i, 1)
            v = v * 16 + index("0123456789abcdef", tolower(c)) - 1
        }
        return v
    }
    {
        w[NR-1] = tolower($1)
    }
    END {
        n = NR
        p1 = -1; p2 = -1; p2_reg = -1; p3 = -1; p3_insn = ""
        for (i = 0; i < n - 12; i++) {
            # 1. cmp wN, #7 (71001c1f..71001fff) + b.eq (54000xx0) + cmp wN, #6 + b.ne
            if (p1 == -1 && w[i] ~ /^71001[cdef][0-9a-f]f$/ && w[i+1] ~ /^54000[0-9a-f]{2}0$/ && w[i+2] ~ /^71001[89ab][0-9a-f]f$/ && w[i+3] ~ /^54000[0-9a-f]{2}1$/) {
                # Check b.eq forward offset is small (8..24 insns)
                imm = int(hex2dec(substr(w[i+1], 3, 5)) / 2)
                if (imm >= 8 && imm <= 24) {
                    p1 = (i + 1) * 4
                }
            }
            # 2. mov wR, #0x8009 (52900120..5290013f) near cmp xK, #0x8000 (f140201f..f14023ff)
            if (p2 == -1 && i >= 6 && w[i] ~ /^529001[23][0-9a-f]$/) {
                for (k = 1; k <= 7; k++) {
                    if (w[i-k] ~ /^f1402[0123][0-9a-f]f$/) {
                        p2 = i * 4
                        p2_reg = hex2dec(w[i]) % 32
                        break
                    }
                }
            }
            # 3. ldrb + tbnz xR, #4, ... before mov wA, #0x20; mov wB, #0x1 at i+7
            if (p3 == -1 && i >= 1 && w[i-1] ~ /^394[0-9a-f]{5}$/ && w[i] ~ /^372[0-7][0-9a-f]{4}$/) {
                if (w[i+7] ~ /^528004[01][0-9a-f]$/ && w[i+8] ~ /^528000[23][0-9a-f]$/) {
                    p3 = i * 4
                    p3_reg = hex2dec(w[i]) % 32
                }
            }
        }
        printf "%d %d %d %d %d\n", p1, p2, p2_reg, p3, p3_reg
    }')

    set -- $res
    local p1="$1" p2="$2" p2_reg="$3" p3="$4" p3_reg="$5"

    if [ "$p1" = "-1" ] || [ "$p2" = "-1" ]; then
        echo "ERR: Could not locate LHDCv5 patterns in $src (p1=$p1 p2=$p2 p3=$p3)" >&2
        return 1
    fi

    # Patch 1: NOP out "LHDCv5 codec disabled" branch
    patch_4bytes_le "$dst" "$p1" "d503201f"

    # Patch 2: Default quality mode = 0x8006 (500 kbps) on register p2_reg
    local q_hex
    q_hex=$(printf "%08x" $((0x529000c0 + p2_reg)))
    patch_4bytes_le "$dst" "$p2" "$q_hex"

    # Patch 3 (optional): Prefer 192kHz over 48kHz (tbnz xR, #0, +0x1c -> 0x370000e0 + p3_reg)
    if [ "$p3" != "-1" ]; then
        local sr_hex
        sr_hex=$(printf "%08x" $((0x370000e0 + p3_reg)))
        patch_4bytes_le "$dst" "$p3" "$sr_hex"
    fi

    cat > "$conf" <<EOF
QUALITY_OFF=$p2
QUALITY_REG=$p2_reg
EOF
    echo "OK: Patched libbluetooth_jni.so (enable=$p1, quality=$p2[w$p2_reg], sr192=$p3)"
    return 0
}

patch_audio_aidl() {
    local src="$1" dst="$2"
    cp "$src" "$dst" || return 1

    local offs
    offs=$(run_od "$dst" | awk '
    {
        w[NR-1] = tolower($1)
    }
    END {
        for (i = 0; i < NR - 3; i++) {
            if (w[i] == "0000ac44" && w[i+1] == "0000bb80" && w[i+2] == "00015888" && w[i+3] == "00017700") {
                printf "%d ", (i + 2) * 4
            }
        }
    }')

    if [ -z "$offs" ]; then
        echo "WARN: 44.1/48/88.2/96k table not found in $src (may already support 192kHz)" >&2
        return 0
    fi

    for off in $offs; do
        # Replace 88200 (0x00015888) with 192000 (0x0002ee00)
        patch_4bytes_le "$dst" "$off" "0002ee00"
    done
    echo "OK: Patched $src for 192kHz software PCM (offsets: $offs)"
    return 0
}
