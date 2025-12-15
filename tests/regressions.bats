setup_file() {
  asdf plugin add pnpm "${ASDF_PNPM_PLUGIN_REPO}"
  PATH="$HOME/.asdf/shims:$PATH"
}

# Wrapper that patches shebangs if NIX_NODE_PATH is set, then runs pnpm
pnpm_wrapper() {
  if [ -n "${NIX_NODE_PATH:-}" ]; then
    local pnpm_path
    pnpm_path="$(command -v pnpm)"
    if [ -f "$pnpm_path" ] && head -1 "$pnpm_path" | grep -q '^#!/usr/bin/env node'; then
      sed -i "1s|^#!/usr/bin/env node|#!${NIX_NODE_PATH}|" "$pnpm_path"
    fi
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
