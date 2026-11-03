#!/usr/bin/env bats
# shellcheck disable=SC2016 # stub bodies are single-quoted on purpose

# list-all and download must go through the npm CLI when it is available, so
# registries that reject anonymous requests (an .npmrc `_authToken`, e.g.
# Artifactory or AWS CodeArtifact) work. See #33. Stubs keep this offline.

setup() {
  PLUGIN_DIR="${ASDF_PNPM_PLUGIN_REPO}"
  STUB_DIR="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$STUB_DIR"
  BASH_BIN=$(command -v bash)
  export PATH="${STUB_DIR}:${PATH}"
}

# stub <name> <body>: an executable on PATH that runs <body> under bash.
stub() {
  printf '#!%s\n%s\n' "$BASH_BIN" "$2" >"${STUB_DIR}/$1"
  chmod +x "${STUB_DIR}/$1"
}

@test "list-all uses npm view when npm is available" {
  stub npm 'case "$1" in
  config) echo "https://registry.invalid/" ;;
  view) printf "[\n  \"1.0.0\",\n  \"10.0.0\",\n  \"2.0.0\"\n]\n" ;;
  *) exit 1 ;;
esac'
  stub curl 'echo "curl must not be called" >&2; exit 99'

  run "${PLUGIN_DIR}/bin/list-all"
  [ "$status" -eq 0 ]
  [ "$output" = "1.0.0 2.0.0 10.0.0" ]
}

@test "list-all falls back to the registry over curl when npm view fails" {
  stub npm 'case "$1" in
  config) echo "https://registry.invalid/" ;;
  *) echo "npm error code E401" >&2; exit 1 ;;
esac'
  stub curl 'printf "{\"versions\":{\"3.0.0\":{\"name\":\"pnpm\"}}}"'

  run "${PLUGIN_DIR}/bin/list-all"
  [ "$status" -eq 0 ]
  [[ $output == *"3.0.0" ]]
  [[ $output == *"E401"* ]]
}

@test "download uses npm pack when npm is available" {
  stub npm 'case "$1" in
  config) echo "https://registry.invalid/" ;;
  pack)
    for arg; do [[ ${prev:-} == --pack-destination ]] && dest=$arg; prev=$arg; done
    work=$(mktemp -d)
    mkdir -p "${work}/package"
    echo "{\"name\":\"pnpm\",\"version\":\"${2#pnpm@}\"}" >"${work}/package/package.json"
    tar czf "${dest}/pnpm-${2#pnpm@}.tgz" -C "$work" package
    echo "pnpm-${2#pnpm@}.tgz"
    ;;
  *) exit 1 ;;
esac'
  stub curl 'echo "curl must not be called" >&2; exit 99'

  export ASDF_INSTALL_VERSION=9.9.9
  export ASDF_DOWNLOAD_PATH="${BATS_TEST_TMPDIR}/download"
  run "${PLUGIN_DIR}/bin/download"
  [ "$status" -eq 0 ]
  grep -q '"version":"9.9.9"' "${ASDF_DOWNLOAD_PATH}/package.json"
}
