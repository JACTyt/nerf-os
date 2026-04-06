#!/bin/bash
PASS=0
FAIL=0

assert_contains() {
  local haystack="$1" needle="$2" msg="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo "PASS: $msg"
    PASS=$((PASS+1))
  else
    echo "FAIL: $msg"
    echo "  Expected to find: $needle"
    echo "  In: $haystack"
    FAIL=$((FAIL+1))
  fi
}

assert_equals() {
  local actual="$1" expected="$2" msg="$3"
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $msg"
    PASS=$((PASS+1))
  else
    echo "FAIL: $msg"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    FAIL=$((FAIL+1))
  fi
}

assert_file_exists() {
  local file="$1" msg="$2"
  if [ -f "$file" ]; then
    echo "PASS: $msg"
    PASS=$((PASS+1))
  else
    echo "FAIL: $msg — file not found: $file"
    FAIL=$((FAIL+1))
  fi
}

run_tests() {
  for test_fn in "$@"; do
    $test_fn
  done
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ]
}
