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

xcodebuild -workspace AppExplorer.xcworkspace -scheme SoqlXplorer -configuration Debug build \
    CODE_SIGN_IDENTITY=- MACOSX_DEPLOYMENT_TARGET=12.0 2>&1 | grep -E "error:|BUILD" || true

APP="$(scripts/resign-debug.sh)"
open "$APP"
