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

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: build.sh must be run as root (required by live-build/debootstrap)."
  exit 1
fi

echo "==> Building NerfOS $VERSION for $ARCH"
mkdir -p "$OUTPUT"

WORK_DIR="$(mktemp -d /tmp/nerfo-build-XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$WORK_DIR"

# Copy live-build config
cp -r "$BUILD_DIR/config" .

# Merge arch-specific overrides
if [ -d "$BUILD_DIR/config/$ARCH" ]; then
  cp -r "$BUILD_DIR/config/$ARCH/." config/
fi

# Copy bootloader configs
cp -r "$BUILD_DIR/bootloaders/grub" config/bootloaders/ 2>/dev/null || true

# Set architecture
lb config \
  --architecture "$ARCH" \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --memtest none \
  --bootappend-live "boot=live quiet splash" \
  --iso-volume "NerfOS-$VERSION" \
  --image-name "nerf-os-$VERSION-$ARCH"

echo "==> Running lb build (this takes 15-30 minutes)..."
lb build

ISO="nerf-os-$VERSION-$ARCH.iso"
cp "$WORK_DIR/$ISO" "$OUTPUT/$ISO"
echo "==> Done: $OUTPUT/$ISO"
ls -lh "$OUTPUT/$ISO"
