#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
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

  # Patch shebangs for Nix sandbox compatibility
  if [ -n "${NIX_NODE_PATH:-}" ]; then
    for f in "$ASDF_INSTALL_PATH"/bin/*.cjs "$ASDF_INSTALL_PATH"/bin/*.js "$ASDF_INSTALL_PATH"/lib/bin/*.js; do
      if [ -f "$f" ] && head -1 "$f" | grep -q '^#!/usr/bin/env node'; then
        sed -i "1s|^#!/usr/bin/env node|#!${NIX_NODE_PATH}|" "$f"
      fi
    done 2>/dev/null || true
  fi
}

get_versions_to_test() {
  # Get latest stable version of major versions 8, 9, 10
  # list-all returns versions in sorted order, so tail -1 gives the latest
  local all_versions
  all_versions=$("$PLUGIN_DIR/bin/list-all" | tr ' ' '\n')
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
  version=$("$PLUGIN_DIR/bin/list-all" | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  install_pnpm "$version"

  run "$ASDF_INSTALL_PATH/bin/pnpm" --help
  [ "$status" -eq 0 ]
  [[ $output == *"pnpm"* ]]
}

@test "pnpx binary is available" {
  version=$("$PLUGIN_DIR/bin/list-all" | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  install_pnpm "$version"

  [ -x "$ASDF_INSTALL_PATH/bin/pnpx" ]
}
