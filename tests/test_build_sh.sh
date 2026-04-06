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

run_tests test_build_sh_usage test_build_sh_invalid_arch
