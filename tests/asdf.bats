#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
}

# Build a test command that patches shebangs if NIX_NODE_PATH is set, then runs pnpm --version
get_test_command() {
  if [ -n "${NIX_NODE_PATH:-}" ]; then
    # Patch shebangs before running pnpm
    echo "for f in bin/pnpm.cjs bin/pnpm.js lib/bin/pnpm.js; do [ -f \"\$f\" ] && sed -i \"1s|^#!/usr/bin/env node|#!${NIX_NODE_PATH}|\" \"\$f\"; done;"
  fi

  echo "pnpm --version"
}

@test "asdf plugin test v8" {
  # Resolve latest v8 version (asdf plugin test doesn't support latest:X syntax in Go version)
  local version
  version=$("$PLUGIN_DIR/bin/latest-stable" 8)
  [[ -n $version ]] || {
    echo "Failed to resolve latest v8 version"
    return 1
  }
  # Remove any leftover test plugin
  asdf plugin remove pnpm-test-v8 2>/dev/null || true
  asdf plugin test \
    pnpm-test-v8 \
    "$PLUGIN_DIR" \
    --asdf-tool-version="$version" \
    "$(get_test_command)"
}

@test "asdf plugin test v9" {
  # Resolve latest v9 version (asdf plugin test doesn't support latest:X syntax in Go version)
  local version
  version=$("$PLUGIN_DIR/bin/latest-stable" 9)
  [[ -n $version ]] || {
    echo "Failed to resolve latest v9 version"
    return 1
  }
  # Remove any leftover test plugin
  asdf plugin remove pnpm-test-v9 2>/dev/null || true
  asdf plugin test \
    pnpm-test-v9 \
    "$PLUGIN_DIR" \
    --asdf-tool-version="$version" \
    "$(get_test_command)"
}

@test "asdf plugin test v10" {
  # Resolve latest v10 version (asdf plugin test doesn't support latest:X syntax in Go version)
  local version
  version=$("$PLUGIN_DIR/bin/latest-stable" 10)
  [[ -n $version ]] || {
    echo "Failed to resolve latest v10 version"
    return 1
  }
  # Remove any leftover test plugin
  asdf plugin remove pnpm-test-v10 2>/dev/null || true
  asdf plugin test \
    pnpm-test-v10 \
    "$PLUGIN_DIR" \
    --asdf-tool-version="$version" \
    "$(get_test_command)"
}
