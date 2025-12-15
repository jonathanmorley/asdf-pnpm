setup_file() {
  asdf plugin add pnpm "${ASDF_PNPM_PLUGIN_REPO}"
  PATH="$HOME/.asdf/shims:$PATH"
}

# Patches shebang from #!/usr/bin/env node to NIX_NODE_PATH if set
patch_shebang() {
  local file="$1"
  if [ -f "$file" ] && head -1 "$file" | grep -q '^#!/usr/bin/env node'; then
    sed -i "1s|^#!/usr/bin/env node|#!${NIX_NODE_PATH}|" "$file"
  fi
}

# Wrapper that patches shebangs if NIX_NODE_PATH is set, then runs pnpm
pnpm_wrapper() {
  if [ -n "${NIX_NODE_PATH:-}" ]; then
    patch_shebang "$(command -v pnpm)"
    patch_shebang "$(asdf which pnpm)"
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
