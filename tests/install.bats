#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export PLUGIN_DIR
  
  # Get versions to test - latest stable of each major version
  ALL_VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  STABLE_VERSIONS=$(echo "$ALL_VERSIONS" | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$')
  MAJOR_VERSIONS=$(echo "$STABLE_VERSIONS" | sed 's/\..*//' | sort -n | uniq)
  
  PNPM_VERSIONS=()
  for major in $MAJOR_VERSIONS; do
    latest=$(echo "$STABLE_VERSIONS" | grep "^${major}\." | tail -1)
    PNPM_VERSIONS+=("$latest")
  done
  export PNPM_VERSIONS
}

teardown() {
  if [ -n "${ASDF_INSTALL_PATH:-}" ]; then
    rm -rf "$ASDF_INSTALL_PATH"
  fi
}

install_pnpm() {
  local version="$1"
  export ASDF_INSTALL_VERSION="$version"
  export ASDF_INSTALL_TYPE="version"
  export ASDF_INSTALL_PATH="${TMPDIR:-/tmp}/asdf-pnpm-test-${version}"
  
  rm -rf "$ASDF_INSTALL_PATH"
  bash "$PLUGIN_DIR/bin/install"
}

@test "install script exists and is executable" {
  [ -f "$PLUGIN_DIR/bin/install" ]
  [ -x "$PLUGIN_DIR/bin/install" ]
}

@test "install pnpm 8.15.9" {
  install_pnpm "8.15.9"
  
  [ -x "$ASDF_INSTALL_PATH/bin/pnpm" ]
  
  INSTALLED_VERSION=$("$ASDF_INSTALL_PATH/bin/pnpm" --version)
  [ "$INSTALLED_VERSION" = "8.15.9" ]
}

@test "install pnpm 9.15.9" {
  install_pnpm "9.15.9"
  
  [ -x "$ASDF_INSTALL_PATH/bin/pnpm" ]
  
  INSTALLED_VERSION=$("$ASDF_INSTALL_PATH/bin/pnpm" --version)
  [ "$INSTALLED_VERSION" = "9.15.9" ]
}

@test "install latest pnpm 10.x" {
  # Get the latest 10.x version
  ALL_VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  LATEST_10=$(echo "$ALL_VERSIONS" | tr ' ' '\n' | grep -E '^10\.[0-9]+\.[0-9]+$' | tail -1)
  
  install_pnpm "$LATEST_10"
  
  [ -x "$ASDF_INSTALL_PATH/bin/pnpm" ]
  
  INSTALLED_VERSION=$("$ASDF_INSTALL_PATH/bin/pnpm" --version)
  [ "$INSTALLED_VERSION" = "$LATEST_10" ]
}

@test "pnpm binary works correctly" {
  install_pnpm "9.15.9"
  
  # Test that pnpm can show help
  run "$ASDF_INSTALL_PATH/bin/pnpm" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"pnpm"* ]]
}

@test "pnpx binary is available" {
  install_pnpm "9.15.9"
  
  [ -x "$ASDF_INSTALL_PATH/bin/pnpx" ]
}
