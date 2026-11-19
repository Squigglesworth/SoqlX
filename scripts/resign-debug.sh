#!/bin/bash
# Re-signs the Debug build of SoqlX with the ad hoc identity so that the embedded
# frameworks share the app's signature. Without this macOS refuses to load the
# prebuilt Sparkle framework (it carries Sparkle's team ID, the ad hoc app has
# none) and the app dies at launch. Every build produces an unsigned-mismatched
# bundle again, so run this after any build or test run.
#
# Prints the path of the app bundle on success.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="$(xcodebuild -workspace AppExplorer.xcworkspace -scheme SoqlXplorer -configuration Debug -showBuildSettings 2>/dev/null \
      | awk '/ BUILT_PRODUCTS_DIR =/ {print $3}')/SoqlXplorer.app"
if [ ! -d "$APP" ]; then
    echo "Debug build not found at $APP, run scripts/run-debug.sh first" >&2
    exit 1
fi
codesign --force --deep --sign - "$APP" 2>/dev/null
echo "$APP"
