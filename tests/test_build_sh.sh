#!/bin/bash
source tests/test_helpers.sh

test_build_sh_usage() {
  output=$(bash build/build.sh 2>&1)
  assert_contains "$output" "Usage:" "build.sh should print usage when no arch given"
}

test_build_sh_invalid_arch() {
  output=$(bash build/build.sh arm64 2>&1)
  assert_contains "$output" "Error" "build.sh should error on unsupported arch"
}

test_package_lists_exist() {
  assert_file_exists "build/config/common/package-lists/base.list.chroot" \
    "base package list exists"
  assert_file_exists "build/config/common/package-lists/gui.list.chroot" \
    "GUI package list exists"
  assert_file_exists "build/config/common/package-lists/terminal.list.chroot" \
    "terminal package list exists"
}

test_no_banned_packages() {
  for list in build/config/common/package-lists/*.list.chroot; do
    for banned in snapd flatpak pulseaudio cups bluetooth bluez avahi-daemon; do
      if grep -q "^$banned$" "$list" 2>/dev/null; then
        echo "FAIL: banned package '$banned' found in $list"
        FAIL=$((FAIL+1))
        return
      fi
    done
  done
  echo "PASS: no banned packages in package lists"
  PASS=$((PASS+1))
}

run_tests test_build_sh_usage test_build_sh_invalid_arch \
  test_package_lists_exist test_no_banned_packages
