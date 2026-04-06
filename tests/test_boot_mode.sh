#!/bin/bash
source tests/test_helpers.sh

CORE_SERVICES="build/config/common/includes.chroot/etc/runit/core-services"

test_core_services_exists() {
  assert_file_exists "$CORE_SERVICES" "core-services script exists"
}

test_core_services_executable() {
  if [ -x "$CORE_SERVICES" ]; then
    echo "PASS: core-services is executable"
    PASS=$((PASS+1))
  else
    echo "FAIL: core-services is not executable"
    FAIL=$((FAIL+1))
  fi
}

test_service_run_scripts_exist() {
  local sv_dir="build/config/common/includes.chroot/etc/sv"
  for svc in dbus NetworkManager ufw busybox-syslog lightdm alsa; do
    assert_file_exists "$sv_dir/$svc/run" "$svc run script exists"
  done
}

test_sysctl_config_exists() {
  assert_file_exists \
    "build/config/common/includes.chroot/etc/sysctl.d/99-nerfo.conf" \
    "sysctl performance config exists"
}

test_sysctl_has_swappiness() {
  local file="build/config/common/includes.chroot/etc/sysctl.d/99-nerfo.conf"
  if grep -q "vm.swappiness" "$file" 2>/dev/null; then
    echo "PASS: sysctl has vm.swappiness"
    PASS=$((PASS+1))
  else
    echo "FAIL: sysctl missing vm.swappiness"
    FAIL=$((FAIL+1))
  fi
}

run_tests test_core_services_exists test_core_services_executable \
  test_service_run_scripts_exist \
  test_sysctl_config_exists test_sysctl_has_swappiness
