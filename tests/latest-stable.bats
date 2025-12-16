#!/usr/bin/env bats

load helpers

setup_file() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
  cache_versions
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

@test "latest-stable with filter 6 returns 6.x version" {
  run "$PLUGIN_DIR/bin/latest-stable" 6
  [ "$status" -eq 0 ]
  [[ $output =~ ^6\.[0-9]+\.[0-9]+$ ]]
}

@test "latest-stable with filter 7 returns 7.x version" {
  run "$PLUGIN_DIR/bin/latest-stable" 7
  [ "$status" -eq 0 ]
  [[ $output =~ ^7\.[0-9]+\.[0-9]+$ ]]
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
  all_versions=$(get_cached_versions | tr ' ' '\n' | grep -E '^8\.[0-9]+\.[0-9]+$')
  expected=$(echo "$all_versions" | tail -1)

  run "$PLUGIN_DIR/bin/latest-stable" 8
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}
