#!/bin/bash
# NetHunter Terminal fix for the A137F (32-bit Android userland on a 64-bit kernel).
#
# Symptom: the terminal fails with
#   exec("/data/data/com.offsec.nhterm/files/usr/bin_armv8l/kali"): No such file or directory
# Cause: nhterm (NethunterComponent.init in comp.kt) only extracts its launcher binaries when Java's
# os.arch is "aarch64" or "armv7l". On this phone os.arch is "armv8l", so nothing gets extracted.
# The Kali chroot itself (armhf) is fine.
# Fix: copy the armv7l launcher set out of the installed APK and point bin_armv8l at it; the app's
# own init then links usr/bin to bin_armv8l on every launch.
#
# Run from a PC with the phone on adb. Rerun after reinstalling or clearing the terminal app.
# Works with a root adbd (KernelSU adb_root) or with an su binary in the adb shell.
set -eu

model=$(adb shell getprop ro.product.model | tr -d '\r')
[ "$model" = SM-A137F ] || { echo "connected device is '$model', not SM-A137F - aborting"; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

apk=$(adb shell pm path com.offsec.nhterm | head -1 | cut -d: -f2 | tr -d '\r')
[ -n "$apk" ] || { echo "com.offsec.nhterm is not installed"; exit 1; }
adb pull "$apk" "$work/nhterm.apk" >/dev/null
unzip -q "$work/nhterm.apk" 'assets/bin_armv7l/*' -d "$work/x"
ls -l "$work/x/assets/bin_armv7l"

adb shell 'rm -rf /data/local/tmp/nh_bin_armv7l'
adb push "$work/x/assets/bin_armv7l" /data/local/tmp/nh_bin_armv7l >/dev/null

# adbd is already root when the KernelSU adb_root feature is on (no su binary then)
if [ "$(adb shell id -u | tr -d '\r')" = 0 ]; then rootsh='sh'; else rootsh='su -c sh'; fi
adb shell "$rootsh" <<'EOS'
D=/data/data/com.offsec.nhterm/files/usr
uid=$(stat -c %u /data/data/com.offsec.nhterm)
am force-stop com.offsec.nhterm
mkdir -p $D
chown $uid:$uid $D
rm -rf $D/bin_armv7l
cp -r /data/local/tmp/nh_bin_armv7l $D/bin_armv7l
ln -sfn bin_armv7l $D/bin_armv8l
chown -R $uid:$uid $D/bin_armv7l
chmod 700 $D/bin_armv7l $D/bin_armv7l/*
restorecon -R $D/bin_armv7l
rm -rf /data/local/tmp/nh_bin_armv7l
ls -lZ $D $D/bin_armv7l
EOS
echo "done - open NetHunter Terminal again"
