#!/usr/bin/env bats

load helpers

setup_file() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
  cache_versions
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

  if [[ "$(command -v patchShebangs)" ]]; then
    patchShebangs "$ASDF_INSTALL_PATH"
  fi
}

get_versions_to_test() {
  # Get latest stable version of major versions 8, 9, 10
  # list-all returns versions in sorted order, so tail -1 gives the latest
  local all_versions
  all_versions=$(get_cached_versions | tr ' ' '\n')
  for major in 8 9 10; do
    echo "$all_versions" | grep -E "^${major}\.[0-9]+\.[0-9]+$" | tail -1
  done
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
  version=$(get_cached_versions | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  install_pnpm "$version"

  run "$ASDF_INSTALL_PATH/bin/pnpm" --help
  [ "$status" -eq 0 ]
  [[ $output == *"pnpm"* ]]
}

@test "pnpm dlx works correctly" {
  for version in $(get_versions_to_test); do
    install_pnpm "$version"

    run "$ASDF_INSTALL_PATH/bin/pnpm" dlx npm help
    [ "$status" -eq 0 ]
    [[ $output == *"npm <command>"* ]]
  done
}

@test "pnpx binary is available" {
  version=$(get_cached_versions | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  install_pnpm "$version"

  [ -x "$ASDF_INSTALL_PATH/bin/pnpx" ]
}
