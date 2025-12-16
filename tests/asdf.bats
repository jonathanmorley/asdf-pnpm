#!/usr/bin/env bats

load helpers

setup_file() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
  cache_versions
}

# Build a test command that patches shebangs if NIX_NODE_PATH is set, then runs pnpm --version
get_test_command() {
  if command -v patchShebangs &>/dev/null; then
    # Patch shebangs before running pnpm
    echo "patchShebangs bin; pnpm --version"
  else
    echo "pnpm --version"
  fi
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

  # Remove any leftover test plugin
  asdf plugin remove "pnpm-test-v${major_version}" 2>/dev/null || true

  asdf plugin test \
    "pnpm-test-v${major_version}" \
    "$PLUGIN_DIR" \
    --asdf-tool-version="$version" \
    "$(get_test_command)"
}

@test "asdf plugin test v6" {
  test_pnpm_version 6
}

@test "asdf plugin test v7" {
  test_pnpm_version 7
}

@test "asdf plugin test v8" {
  test_pnpm_version 8
}

@test "asdf plugin test v9" {
  test_pnpm_version 9
}

@test "asdf plugin test v10" {
  test_pnpm_version 10
}
