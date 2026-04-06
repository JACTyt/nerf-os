#!/bin/bash
source tests/test_helpers.sh

# Source only the functions, not the main execution block
NERF_OPTIM_TEST_MODE=1 source scripts/nerf-optim

test_detect_ram_low() {
  local result
  result=$(detect_ram_tier 524288)  # 512MB in KB
  assert_equals "$result" "low" "512MB RAM detected as low tier"
}

test_detect_ram_mid() {
  local result
  result=$(detect_ram_tier 1048576)  # 1GB in KB
  assert_equals "$result" "mid" "1GB RAM detected as mid tier"
}

test_detect_ram_high() {
  local result
  result=$(detect_ram_tier 2097152)  # 2GB in KB
  assert_equals "$result" "high" "2GB RAM detected as high tier"
}

test_calc_zram_size_low() {
  local result
  result=$(calc_zram_size 524288)  # 512MB
  assert_equals "$result" "262144" "zram size is 50% of RAM (KB)"
}

test_browser_cache_low_ram() {
  local result
  result=$(get_browser_cache_mb "low")
  assert_equals "$result" "64" "low RAM gets 64MB browser cache"
}

test_browser_cache_mid_ram() {
  local result
  result=$(get_browser_cache_mb "mid")
  assert_equals "$result" "128" "mid RAM gets 128MB browser cache"
}

run_tests \
  test_detect_ram_low \
  test_detect_ram_mid \
  test_detect_ram_high \
  test_calc_zram_size_low \
  test_browser_cache_low_ram \
  test_browser_cache_mid_ram
