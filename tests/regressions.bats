#!/usr/bin/env bats

load helpers

setup_file() {
  asdf plugin add pnpm "${ASDF_PNPM_PLUGIN_REPO}"
  PATH="$HOME/.asdf/shims:$PATH"
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
  patchAsdf

  [[ "$(pnpm --version)" == "10.12.3" ]]
}
