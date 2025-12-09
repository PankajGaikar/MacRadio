#!/bin/bash

# Script to notarize MacRadio DMG
# Usage: ./scripts/notarize.sh [dmg_path] [keychain_profile]
# 
# Prerequisites:
# 1. Apple Developer account with App-Specific Password
# 2. Keychain profile created: xcrun notarytool store-credentials AC_PASSWORD --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --password YOUR_APP_SPECIFIC_PASSWORD
# 3. Code signed app and DMG

set -e

DMG_PATH=${1:-"build/MacRadio-1.0.0.dmg"}
KEYCHAIN_PROFILE=${2:-"AC_PASSWORD"}

if [ ! -f "${DMG_PATH}" ]; then
    echo "Error: DMG not found at ${DMG_PATH}"
    exit 1
fi

echo "Notarizing ${DMG_PATH}..."

# Submit for notarization
echo "Submitting to Apple for notarization..."
xcrun notarytool submit "${DMG_PATH}" \
    --keychain-profile "${KEYCHAIN_PROFILE}" \
    --wait

# Check notarization status
echo "Checking notarization status..."
xcrun notarytool history --keychain-profile "${KEYCHAIN_PROFILE}"

# Staple the notarization ticket
echo "Stapling notarization ticket..."
xcrun stapler staple "${DMG_PATH}"

# Verify stapling
echo "Verifying stapling..."
xcrun stapler validate "${DMG_PATH}"

echo ""
echo "✅ Notarization complete! DMG is ready for distribution."
echo "DMG: ${DMG_PATH}"

