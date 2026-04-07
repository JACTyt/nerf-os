#!/bin/bash
source tests/test_helpers.sh

NERF_INSTALL_TEST_MODE=1 source scripts/nerf-install

test_detect_bios_mode_uefi() {
  # Simulate UEFI: efivars dir exists
  local fake_efi
  fake_efi=$(mktemp -d)
  local result
  result=$(detect_firmware_mode "$fake_efi")
  assert_equals "$result" "uefi" "detects UEFI when efivars exists"
  rmdir "$fake_efi"
}

test_detect_bios_mode_bios() {
  local result
  result=$(detect_firmware_mode "/nonexistent_efivars_path_xyz")
  assert_equals "$result" "bios" "detects BIOS when efivars absent"
}

test_calc_swap_size_low_ram() {
  local result
  result=$(calc_swap_partition_gb 512)  # 512MB RAM
  assert_equals "$result" "2" "512MB RAM gets 2GB swap partition"
}

test_no_swap_high_ram() {
  local result
  result=$(calc_swap_partition_gb 4096)  # 4GB RAM
  assert_equals "$result" "0" "4GB RAM gets no swap partition"
}

test_validate_disk_rejects_empty() {
  local result
  result=$(validate_disk_input "" 2>&1)
  assert_contains "$result" "Error" "empty disk input rejected"
}

run_tests \
  test_detect_bios_mode_uefi \
  test_detect_bios_mode_bios \
  test_calc_swap_size_low_ram \
  test_no_swap_high_ram \
  test_validate_disk_rejects_empty
