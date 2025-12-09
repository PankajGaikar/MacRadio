#!/bin/bash

# Script to create a DMG for MacRadio distribution
# Usage: ./scripts/create_dmg.sh [version]

set -e

VERSION=${1:-"1.0.0"}
APP_NAME="MacRadio"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build"
DMG_DIR="${BUILD_DIR}/dmg"
APP_PATH="${BUILD_DIR}/Release/${APP_NAME}.app"
DMG_TEMP="${BUILD_DIR}/${APP_NAME}-temp.dmg"

echo "Creating DMG for ${APP_NAME} ${VERSION}..."

# Clean previous builds
rm -rf "${BUILD_DIR}"
mkdir -p "${DMG_DIR}"

# Check if app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "Error: ${APP_PATH} not found. Please build the app first."
    echo "Run: xcodebuild -project MacRadio.xcodeproj -scheme MacRadio -configuration Release archive"
    exit 1
fi

# Copy app to DMG directory
cp -R "${APP_PATH}" "${DMG_DIR}/"

# Create Applications symlink
ln -s /Applications "${DMG_DIR}/Applications"

# Create DMG
echo "Creating disk image..."
hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_DIR}" -ov -format UDZO "${DMG_TEMP}"

# Rename to final DMG name
mv "${DMG_TEMP}" "${BUILD_DIR}/${DMG_NAME}"

echo "DMG created: ${BUILD_DIR}/${DMG_NAME}"
echo ""
echo "Next steps:"
echo "1. Code sign the app (if not already done)"
echo "2. Notarize the DMG: xcrun notarytool submit ${BUILD_DIR}/${DMG_NAME} --keychain-profile \"AC_PASSWORD\" --wait"
echo "3. Staple the notarization: xcrun stapler staple ${BUILD_DIR}/${DMG_NAME}"

