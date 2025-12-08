#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export PLUGIN_DIR
}

@test "latest-stable script exists and is executable" {
  [ -f "$PLUGIN_DIR/bin/latest-stable" ]
  [ -x "$PLUGIN_DIR/bin/latest-stable" ]
}

@test "latest-stable returns a version without filter" {
  run "$PLUGIN_DIR/bin/latest-stable"
  [ "$status" -eq 0 ]
  [[ $output =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "latest-stable with filter 8 returns 8.x version" {
  run "$PLUGIN_DIR/bin/latest-stable" 8
  [ "$status" -eq 0 ]
  [[ $output =~ ^8\.[0-9]+\.[0-9]+$ ]]
}

@test "latest-stable with filter 9 returns 9.x version" {
  run "$PLUGIN_DIR/bin/latest-stable" 9
  [ "$status" -eq 0 ]
  [[ $output =~ ^9\.[0-9]+\.[0-9]+$ ]]
}

@test "latest-stable with filter 10 returns 10.x version" {
  run "$PLUGIN_DIR/bin/latest-stable" 10
  [ "$status" -eq 0 ]
  [[ $output =~ ^10\.[0-9]+\.[0-9]+$ ]]
}

@test "latest-stable excludes prerelease versions" {
  # Ensure the output is a stable version (no alpha, beta, rc, etc.)
  run "$PLUGIN_DIR/bin/latest-stable"
  [ "$status" -eq 0 ]
  # Should not contain prerelease identifiers
  [[ ! $output =~ (alpha|beta|rc|dev|canary|-) ]]
}

@test "latest-stable with non-matching filter returns empty" {
  run "$PLUGIN_DIR/bin/latest-stable" 999
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "latest-stable returns latest within major version" {
  # Get all 8.x versions and verify latest-stable returns the highest
  all_versions=$("$PLUGIN_DIR/bin/list-all" | tr ' ' '\n' | grep -E '^8\.[0-9]+\.[0-9]+$')
  expected=$(echo "$all_versions" | tail -1)

  run "$PLUGIN_DIR/bin/latest-stable" 8
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}
