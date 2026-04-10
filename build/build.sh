#!/bin/bash
set -euo pipefail

ARCH="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR"
VERSION="1.0"
OUTPUT="$REPO_ROOT/output"

usage() {
  echo "Usage: $0 [x86_64|i686]"
  echo ""
  echo "Builds NerfOS ISO for the specified architecture."
  echo ""
  echo "Examples:"
  echo "  $0 x86_64    # Build 64-bit ISO"
  echo "  $0 i686      # Build 32-bit ISO"
  exit 1
}

if [ -z "$ARCH" ]; then
  usage
fi

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "i686" ]; then
  echo "Error: unsupported architecture '$ARCH'. Use x86_64 or i686."
  exit 1
fi

# Map to Debian architecture names used by live-build
case "$ARCH" in
  x86_64) DEB_ARCH="amd64" ;;
  i686)   DEB_ARCH="i386"  ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: build.sh must be run as root (required by live-build/debootstrap)."
  exit 1
fi

echo "==> Building NerfOS $VERSION for $ARCH"
mkdir -p "$OUTPUT"

WORK_DIR="$(mktemp -d /tmp/nerfo-build-XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$WORK_DIR"

# live-build expects: config/package-lists/, config/hooks/,
# config/includes.chroot/ directly under config/ — not under config/common/.
# Flatten build/config/common/ into config/.
mkdir -p config
cp -r "$BUILD_DIR/config/common/." config/

# Place arch-specific lb config vars as config/common (a file, not a dir)
if [ -f "$BUILD_DIR/config/$ARCH/common" ]; then
  cp "$BUILD_DIR/config/$ARCH/common" config/common
fi

# Copy bootloader configs
cp -r "$BUILD_DIR/bootloaders/grub" config/bootloaders/ 2>/dev/null || true

# Set architecture
lb config \
  --architecture "$DEB_ARCH" \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap "http://deb.debian.org/debian/" \
  --mirror-chroot "http://deb.debian.org/debian/" \
  --mirror-chroot-security "http://security.debian.org/debian-security/" \
  --mirror-binary "http://deb.debian.org/debian/" \
  --mirror-binary-security "http://security.debian.org/debian-security/" \
  --debootstrap-options "--exclude=systemd,systemd-sysv" \
  --apt-options "-o APT::Install-Recommends=false -o APT::Get::Assume-Yes=true -o DPkg::Options::=--force-confdef -o DPkg::Options::=--force-confold" \
  --debian-installer none \
  --memtest none \
  --bootappend-live "boot=live quiet splash" \
  --iso-volume "NerfOS-$VERSION"

echo "==> Running lb build (this takes 15-30 minutes)..."
lb build

# live-build names the output live-image-ARCH.hybrid.iso
LB_ISO=$(find "$WORK_DIR" -maxdepth 1 -name "*.iso" | head -1)
if [ -z "$LB_ISO" ]; then
  echo "Error: no ISO found in $WORK_DIR after build"
  ls -la "$WORK_DIR"
  exit 1
fi

ISO_OUT="$OUTPUT/nerf-os-$VERSION-$ARCH.iso"
cp "$LB_ISO" "$ISO_OUT"
echo "==> Done: $ISO_OUT"
ls -lh "$ISO_OUT"
