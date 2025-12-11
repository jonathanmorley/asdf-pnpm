setup() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  export PLUGIN_DIR
}

# https://github.com/jonathanmorley/asdf-pnpm/issues/35
@test "corepack compatibility" {
  cd "$BATS_TEST_TMPDIR"

  printf "pnpm 10.11.0\n" >.tool-versions
  echo '{
  "devEngines": {
    "packageManager": {
      "name": "pnpm",
      "onFail": "error"
    }
  }
}' >package.json

  cat .tool-versions
  cat package.json

  asdf plugin add pnpm "${PLUGIN_DIR}"
  
  # This currently fails due to a corepack mismatch of the npm command used by the asdf pnpm plugin
  run ! asdf install pnpm
}
