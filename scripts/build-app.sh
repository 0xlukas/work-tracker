#!/bin/sh
# Build a release WorkTracker.app.
#
#   scripts/build-app.sh [output-folder]          # default: .build/app
#   BUNDLE_ID=com.example.test scripts/build-app.sh /tmp/test   # separate settings domain
#
# The compiled String Catalog is copied into Contents/Resources/<lang>.lproj, where
# Localization looks for it first.
set -eu
cd "$(dirname "$0")/.."

OUT="${1:-.build/app}"
BUNDLE_ID="${BUNDLE_ID:-com.worktracker.app}"
VERSION="${VERSION:-1.7}"
BUILD="${BUILD:-11}"

swift build -c release
BIN="$(swift build -c release --show-bin-path)"
APP="$OUT/WorkTracker.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/WorkTracker" "$APP/Contents/MacOS/WorkTracker"
cp -R "$BIN/WorkTracker_WorkTracker.bundle/Contents/Resources/"*.lproj "$APP/Contents/Resources/"
# Liquid Glass icon: actool compiles the Icon Composer file into Assets.car (the layered
# icon macOS 26+ renders, incl. dark/tinted variants) plus a flat AppIcon.icns fallback.
# actool needs absolute paths; OUT may be relative or absolute.
RESOURCES="$(cd "$APP/Contents/Resources" && pwd)"
xcrun actool "$PWD/Resources/AppIcon.icon" --compile "$RESOURCES" \
    --platform macosx --minimum-deployment-target 27.0 --app-icon AppIcon \
    --output-partial-info-plist "$RESOURCES/../icon-info.plist" >/dev/null
rm -f "$RESOURCES/../icon-info.plist"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key><string>Work Tracker</string>
    <key>CFBundleExecutable</key><string>WorkTracker</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIconName</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleName</key><string>Work Tracker</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$BUILD</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>de</string></array>
    <key>LSMinimumSystemVersion</key><string>27.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP ($BUNDLE_ID $VERSION/$BUILD)"
