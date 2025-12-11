#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
}

# Build a test command that patches shebangs if NIX_NODE_PATH is set, then runs pnpm --version
get_test_command() {
  if [ -n "${NIX_NODE_PATH:-}" ]; then
    # Patch shebangs before running pnpm
    echo "for f in bin/pnpm.cjs bin/pnpm.js lib/bin/pnpm.js; do [ -f \"\$f\" ] && sed -i \"1s|^#!/usr/bin/env node|#!${NIX_NODE_PATH}|\" \"\$f\"; done; pnpm --version"
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
