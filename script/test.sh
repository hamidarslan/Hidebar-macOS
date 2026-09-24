#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# The Swift 6.4 Command Line Tools omit this plugin from the default test invocation.
DEVELOPER_DIR_PATH="$(xcode-select -p)"
PLUGIN="$DEVELOPER_DIR_PATH/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
if [[ -f "$PLUGIN" ]]; then
    swift test -Xswiftc -load-plugin-library -Xswiftc "$PLUGIN"
else
    swift test
fi
