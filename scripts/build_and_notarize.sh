#!/bin/bash

# Complete build, DMG creation, and notarization script
# Usage: ./scripts/build_and_notarize.sh [version] [keychain_profile]

set -e

VERSION=${1:-"1.0.0"}
KEYCHAIN_PROFILE=${2:-"AC_PASSWORD"}
SCHEME="MacRadio"
PROJECT="MacRadio.xcodeproj"
ARCHIVE_PATH="build/MacRadio.xcarchive"
APP_PATH="build/Release/MacRadio.app"
DMG_PATH="build/MacRadio-${VERSION}.dmg"

echo "🚀 Building and notarizing MacRadio ${VERSION}..."
echo ""

# Step 1: Clean build folder
echo "📦 Cleaning build folder..."
rm -rf build
mkdir -p build

# Step 2: Archive the app
echo "📦 Archiving app..."
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_STYLE="Manual"

# Step 3: Export the app
echo "📦 Exporting app..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "build/Release" \
    -exportOptionsPlist exportOptions.plist || {
    echo "Note: If exportOptions.plist doesn't exist, copying app manually..."
    cp -R "${ARCHIVE_PATH}/Products/Applications/MacRadio.app" "${APP_PATH}"
}

# Step 4: Code sign the app (if not already signed)
echo "✍️  Code signing app..."
codesign --force --deep --sign "Developer ID Application" "${APP_PATH}" || {
    echo "Warning: Code signing failed. Make sure you have a Developer ID certificate."
}

# Step 5: Create DMG
echo "💿 Creating DMG..."
./scripts/create_dmg.sh "${VERSION}"

# Step 6: Code sign the DMG
echo "✍️  Code signing DMG..."
codesign --force --sign "Developer ID Application" "${DMG_PATH}" || {
    echo "Warning: DMG code signing failed."
}

# Step 7: Notarize
echo "🔐 Notarizing DMG..."
./scripts/notarize.sh "${DMG_PATH}" "${KEYCHAIN_PROFILE}"

echo ""
echo "✅ Build and notarization complete!"
echo "📦 DMG ready: ${DMG_PATH}"

