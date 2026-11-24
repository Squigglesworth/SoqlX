#!/bin/bash
# Builds the Debug app from the command line, re-signs it so the embedded
# frameworks share the app's (ad hoc) signature, and launches it.
#
# Without the re-sign, macOS refuses to load Sparkle.framework because the
# prebuilt framework carries the Sparkle team ID while an ad hoc signed app
# has none, and dyld treats the mismatch as fatal.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d AppExplorer.xcworkspace ]; then
    echo "AppExplorer.xcworkspace is missing, run 'pod install' first" >&2
    exit 1
fi

LOG="$(mktemp -t soqlx-build)"
if ! xcodebuild -workspace AppExplorer.xcworkspace -scheme SoqlXplorer -configuration Debug build \
    CODE_SIGN_IDENTITY=- MACOSX_DEPLOYMENT_TARGET=12.0 >"$LOG" 2>&1; then
    # Stop here: launching would open the previous build and hide the failure.
    grep -E "error:" "$LOG" | sort -u >&2 || true
    echo "BUILD FAILED. Full log: $LOG" >&2
    exit 1
fi
grep -E "warning:.*(Settings|Sidebar|Shell/)" "$LOG" | sort -u | head -20 || true
echo "BUILD SUCCEEDED"

APP="$(scripts/resign-debug.sh)"
open "$APP"
