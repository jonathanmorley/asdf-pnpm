#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
}

@test "asdf plugin test v8" {
  # Resolve latest v8 version (asdf plugin test doesn't support latest:X syntax in Go version)
  local version
  version=$("$PLUGIN_DIR/bin/latest-stable" 8)
  [[ -n $version ]] || {
    echo "Failed to resolve latest v8 version"
    return 1
  }
  asdf plugin test \
    pnpm \
    "$PLUGIN_DIR" \
    --asdf-tool-version="$version" \
    'pnpm --version'
}

@test "asdf plugin test v9" {
  # Resolve latest v9 version (asdf plugin test doesn't support latest:X syntax in Go version)
  local version
  version=$("$PLUGIN_DIR/bin/latest-stable" 9)
  [[ -n $version ]] || {
    echo "Failed to resolve latest v9 version"
    return 1
  }
  asdf plugin test \
    pnpm \
    "$PLUGIN_DIR" \
    --asdf-tool-version="$version" \
    'pnpm --version'
}

@test "asdf plugin test v10" {
  # Resolve latest v10 version (asdf plugin test doesn't support latest:X syntax in Go version)
  local version
  version=$("$PLUGIN_DIR/bin/latest-stable" 10)
  [[ -n $version ]] || {
    echo "Failed to resolve latest v10 version"
    return 1
  }
  asdf plugin test \
    pnpm \
    "$PLUGIN_DIR" \
    --asdf-tool-version="$version" \
    'pnpm --version'
}
