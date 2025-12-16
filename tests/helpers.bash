#!/usr/bin/env bash

# Shared test helpers for asdf-pnpm bats tests

# Cache file for list-all results
CACHE_FILE="${BATS_FILE_TMPDIR:-/tmp}/asdf-pnpm-versions-cache"

# Cache the list-all output to avoid repeated network calls
cache_versions() {
  if [[ ! -f $CACHE_FILE ]]; then
    "$PLUGIN_DIR/bin/list-all" >"$CACHE_FILE"
  fi
}

# Get cached versions (call cache_versions in setup_file first)
get_cached_versions() {
  cat "$CACHE_FILE"
}

# Patch shebangs in asdf directory for Nix compatibility
patchAsdf() {
  if command -v patchShebangs &>/dev/null; then
    patchShebangs "$HOME/.asdf"
  fi
}
