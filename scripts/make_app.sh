#!/bin/bash
# Builds Deskmates.app, which is how the thing is meant to be run: double
# clicked, in the Applications folder, able to start at login.
#
#     ./scripts/make_app.sh
#     open build/Deskmates.app
set -euo pipefail

cd "$(dirname "$0")/.."

NAME="Deskmates"
DISPLAY="Superstar Deskmates"
IDENTIFIER="com.dhodraj.deskmates"
VERSION="0.1.0"
APP="build/${NAME}.app"

echo "building"
swift build -c release --product "${NAME}"
BIN="$(swift build -c release --show-bin-path)"

echo "assembling ${APP}"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp "${BIN}/${NAME}" "${APP}/Contents/MacOS/${NAME}"
# SwiftPM puts the sprites in their own bundle. It has to sit beside the
# executable's own resources or Bundle.module cannot find it.
cp -R "${BIN}/${NAME}_DeskmatesCore.bundle" "${APP}/Contents/Resources/"

echo "drawing the icon"
python3 scripts/make_logo.py build/icon.png
ICONSET="build/AppIcon.iconset"
rm -rf "${ICONSET}"
mkdir -p "${ICONSET}"
for size in 16 32 128 256 512; do
  sips -z $size $size build/icon.png --out "${ICONSET}/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z $double $double build/icon.png --out "${ICONSET}/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "${ICONSET}" -o "${APP}/Contents/Resources/AppIcon.icns"

cat > "${APP}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${NAME}</string>
  <key>CFBundleDisplayName</key><string>${DISPLAY}</string>
  <key>CFBundleIdentifier</key><string>${IDENTIFIER}</string>
  <key>CFBundleExecutable</key><string>${NAME}</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <!-- No Dock icon and no menu of its own. The app is only its characters. -->
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>MIT licensed</string>
</dict>
</plist>
PLIST

# Signed with an ad-hoc signature, which is enough to run on the Mac that
# built it. Shipping to anyone else needs a Developer ID and notarisation.
codesign --force --sign - "${APP}" >/dev/null 2>&1
codesign --verify --verbose=1 "${APP}" 2>&1 | tail -1

echo "built ${APP}"
