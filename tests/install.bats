#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export PLUGIN_DIR
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

get_versions_to_test() {
  # Get latest stable version of each major
  "$PLUGIN_DIR/bin/list-all" | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | \
    awk -F. '{ if (!seen[$1]++ || $0 > latest[$1]) latest[$1] = $0 } END { for (m in latest) print latest[m] }' | \
    sort -t. -k1,1n
}

@test "install script exists and is executable" {
  [ -f "$PLUGIN_DIR/bin/install" ]
  [ -x "$PLUGIN_DIR/bin/install" ]
}

@test "install and verify all major versions" {
  for version in $(get_versions_to_test); do
    echo "# Testing pnpm $version" >&3
    install_pnpm "$version"
    
    [ -x "$ASDF_INSTALL_PATH/bin/pnpm" ]
    [ "$("$ASDF_INSTALL_PATH/bin/pnpm" --version)" = "$version" ]
    
    rm -rf "$ASDF_INSTALL_PATH"
  done
}

@test "pnpm binary works correctly" {
  version=$("$PLUGIN_DIR/bin/list-all" | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  install_pnpm "$version"
  
  run "$ASDF_INSTALL_PATH/bin/pnpm" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"pnpm"* ]]
}

@test "pnpx binary is available" {
  version=$("$PLUGIN_DIR/bin/list-all" | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  install_pnpm "$version"
  
  [ -x "$ASDF_INSTALL_PATH/bin/pnpx" ]
}
