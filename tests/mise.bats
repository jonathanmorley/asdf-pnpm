#!/usr/bin/env bats

load helpers

setup_file() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
}

# Helper function to test a specific major version of pnpm
# Usage: test_pnpm_version <major_version>
test_pnpm_version() {
  local major_version="$1"
  local version

  # Resolve latest version for this major (asdf plugin test doesn't support latest:X syntax in Go version)
  version=$("$PLUGIN_DIR/bin/latest-stable" "$major_version")
  [[ -n $version ]] || {
    echo "Failed to resolve latest v${major_version} version"
    return 1
  }

  mise plugins link asdf-pnpm "${ASDF_PNPM_PLUGIN_REPO}" --force
  run mise install "asdf-pnpm@${version}" --verbose
  [ "$status" -eq 0 ]
  [[ $output =~ Downloading\ pnpm\ v${version}\ from\ https://registry.npmjs.org/pnpm/-/pnpm-${version}.tgz ]]
}

@test "mise plugin test v6" {
  test_pnpm_version 6
}

@test "mise plugin test v7" {
  test_pnpm_version 7
}

@test "mise plugin test v8" {
  test_pnpm_version 8
}

@test "mise plugin test v9" {
  test_pnpm_version 9
}

@test "mise plugin test v10" {
  test_pnpm_version 10
}
