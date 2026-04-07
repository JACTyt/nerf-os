#!/bin/bash
# test_qemu_boot.sh — headless QEMU boot verification for CI
#
# Extracts the kernel and initrd directly from the ISO so we can pass
# console=ttyS0 via -append, bypassing GRUB (which uses gfxterm and
# would produce no serial output).
#
# Usage: bash tests/test_qemu_boot.sh <path-to-iso>
# Exit:  0 on pass, 1 on fail

set -euo pipefail

ISO="${1:-output/nerf-os-1.0-x86_64.iso}"
BOOT_TIMEOUT=300   # 5 minutes — emulation without KVM is slow
LOG=/tmp/nerfo-qemu-boot.log

if [ ! -f "$ISO" ]; then
  echo "ERROR: ISO not found: $ISO"
  exit 1
fi

echo "==> Mounting ISO to extract kernel and initrd..."
MOUNT_DIR=$(mktemp -d)
sudo mount -o loop,ro "$ISO" "$MOUNT_DIR"
cp "$MOUNT_DIR/live/vmlinuz" /tmp/nerfo-vmlinuz
cp "$MOUNT_DIR/live/initrd.img" /tmp/nerfo-initrd
sudo umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"
echo "    vmlinuz: $(du -h /tmp/nerfo-vmlinuz | cut -f1)"
echo "    initrd:  $(du -h /tmp/nerfo-initrd  | cut -f1)"

# Use KVM if available (10-20x faster)
KVM_FLAG=""
if [ -w /dev/kvm ]; then
  echo "==> KVM available — using hardware acceleration"
  KVM_FLAG="-enable-kvm -cpu host"
else
  echo "==> KVM not available — using software emulation (slow)"
fi

echo "==> Booting ISO in QEMU (terminal mode, serial console, ${BOOT_TIMEOUT}s timeout)..."
echo "    Log: $LOG"

# Boot the live system in terminal mode with serial console.
# grep -m1 exits (and closes the pipe → SIGPIPE to QEMU) as soon as
# it finds the first match, so we don't wait for the full timeout.
set +e
timeout "$BOOT_TIMEOUT" qemu-system-x86_64 \
  -m 512 \
  $KVM_FLAG \
  -kernel /tmp/nerfo-vmlinuz \
  -initrd /tmp/nerfo-initrd \
  -append "boot=live quiet nerf.mode=terminal console=ttyS0 loglevel=4" \
  -nographic \
  -serial stdio \
  -net nic -net user \
  -no-reboot \
  2>&1 | tee "$LOG" | grep -qm1 "login:"
RESULT=$?
set -e

echo ""
echo "==> Evaluating boot result..."

if grep -q "login:" "$LOG"; then
  echo "PASS: system reached login prompt"
  exit 0
fi

# login: not found — check for earlier-stage indicators to give a
# more useful failure message
if grep -q "Freeing unused kernel" "$LOG"; then
  echo "FAIL: kernel booted but init/login never appeared"
  echo "      (runit may have crashed or getty is not on ttyS0)"
elif grep -q "Linux version" "$LOG"; then
  echo "FAIL: kernel started loading but did not complete boot"
  echo "      (possible initrd or live-boot failure)"
else
  echo "FAIL: no kernel output detected on serial console"
  echo "      (QEMU may have failed to start, or console=ttyS0 had no effect)"
fi

echo ""
echo "--- Last 40 lines of boot log ---"
tail -40 "$LOG"
exit 1
