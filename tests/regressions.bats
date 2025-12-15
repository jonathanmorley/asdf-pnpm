setup_file() {
  asdf plugin add pnpm "${ASDF_PNPM_PLUGIN_REPO}"
  PATH="$HOME/.asdf/shims:$PATH"
}

# Wrapper that patches shebangs if NIX_NODE_PATH is set, then runs pnpm
pnpm_wrapper() {
  if [ -n "${NIX_STORE:-}" ]; then
    patchShebangs "$(command -v pnpm)"
    patchShebangs "$(asdf which pnpm)"
  fi

  command pnpm "$@"
}

# https://github.com/jonathanmorley/asdf-pnpm/issues/35
@test "corepack compatibility" {
  cd "$BATS_TEST_TMPDIR"

  echo '{
  "devEngines": {
    "packageManager": {
      "name": "pnpm",
      "onFail": "error"
    }
  }
}' >package.json

  asdf install pnpm 10.11.0
}

# https://github.com/jonathanmorley/asdf-pnpm/issues/37
@test "correct pnpm version for 10.12.3" {
  cd "$BATS_TEST_TMPDIR"

  echo 'pnpm 10.12.3' >.tool-versions

  asdf install

  [[ "$(pnpm_wrapper --version)" == "10.12.3" ]]
}
