setup() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
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

  asdf plugin add pnpm "${PLUGIN_DIR}"
  # This currently fails due to a corepack mismatch of the npm command used by the asdf pnpm plugin
  asdf install pnpm 10.11.0
}
