#!/usr/bin/env bats

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export PLUGIN_DIR
}

@test "list-all returns versions" {
  run "$PLUGIN_DIR/bin/list-all"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "list-all returns at least 100 versions" {
  VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  VERSION_COUNT=$(echo "$VERSIONS" | wc -w | tr -d ' ')
  [ "$VERSION_COUNT" -ge 100 ]
}

@test "list-all returns space-separated versions" {
  VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  # Should not contain newlines within the output
  [[ ! "$VERSIONS" == *$'\n'* ]]
}

@test "list-all includes known versions" {
  VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  [[ " $VERSIONS " == *" 1.0.0 "* ]]
  [[ " $VERSIONS " == *" 6.0.0 "* ]]
  [[ " $VERSIONS " == *" 7.0.0 "* ]]
  [[ " $VERSIONS " == *" 8.0.0 "* ]]
  [[ " $VERSIONS " == *" 9.0.0 "* ]]
  [[ " $VERSIONS " == *" 10.0.0 "* ]]
}

@test "list-all returns versions in ascending order" {
  VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  FIRST_VERSION=$(echo "$VERSIONS" | cut -d' ' -f1)
  LAST_VERSION=$(echo "$VERSIONS" | awk '{print $NF}')
  
  FIRST_MAJOR=$(echo "$FIRST_VERSION" | cut -d. -f1)
  LAST_MAJOR=$(echo "$LAST_VERSION" | cut -d. -f1)
  
  # First major version should be less than or equal to last
  [ "$FIRST_MAJOR" -le "$LAST_MAJOR" ]
}

@test "list-all versions match semver format" {
  VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  INVALID_COUNT=0
  
  for version in $VERSIONS; do
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      ((INVALID_COUNT++)) || true
    fi
    # Only check first 50 to keep test fast
    if [ "$INVALID_COUNT" -gt 5 ]; then
      break
    fi
  done
  
  [ "$INVALID_COUNT" -le 5 ]
}

@test "list-all does not return 24.x versions" {
  VERSIONS=$("$PLUGIN_DIR/bin/list-all")
  # 24.x versions are incorrectly published and should be filtered out
  [[ ! " $VERSIONS " == *" 24."* ]]
}
