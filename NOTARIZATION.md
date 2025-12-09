# Notarization Guide for MacRadio

This guide explains how to create a DMG and notarize it for distribution outside the Mac App Store.

## Prerequisites

1. **Apple Developer Account** with App-Specific Password
2. **Developer ID Certificate** (not App Store certificate)
3. **Team ID** from your Apple Developer account

## Setup

### 1. Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to "Sign-In and Security" → "App-Specific Passwords"
4. Create a new password for "Notarization"
5. Save this password securely

### 2. Store Credentials in Keychain

```bash
xcrun notarytool store-credentials AC_PASSWORD \
    --apple-id YOUR_APPLE_ID \
    --team-id YOUR_TEAM_ID \
    --password YOUR_APP_SPECIFIC_PASSWORD
```

Replace:
- `YOUR_APPLE_ID`: Your Apple ID email
- `YOUR_TEAM_ID`: Your Team ID (found in Apple Developer account)
- `YOUR_APP_SPECIFIC_PASSWORD`: The app-specific password you created

### 3. Update exportOptions.plist

Edit `exportOptions.plist` and replace `YOUR_TEAM_ID` with your actual Team ID.

## Building and Notarizing

### Option 1: Automated Script (Recommended)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Build, create DMG, and notarize
./scripts/build_and_notarize.sh 1.0.0 AC_PASSWORD
```

### Option 2: Manual Steps

#### Step 1: Archive the App

```bash
xcodebuild archive \
    -project MacRadio.xcodeproj \
    -scheme MacRadio \
    -configuration Release \
    -archivePath build/MacRadio.xcarchive \
    CODE_SIGN_IDENTITY="Developer ID Application"
```

#### Step 2: Export the App

```bash
xcodebuild -exportArchive \
    -archivePath build/MacRadio.xcarchive \
    -exportPath build/Release \
    -exportOptionsPlist exportOptions.plist
```

#### Step 3: Create DMG

```bash
./scripts/create_dmg.sh 1.0.0
```

#### Step 4: Code Sign the DMG

```bash
codesign --force --sign "Developer ID Application" build/MacRadio-1.0.0.dmg
```

#### Step 5: Notarize

```bash
./scripts/notarize.sh build/MacRadio-1.0.0.dmg AC_PASSWORD
```

## Verification

After notarization, verify the DMG:

```bash
# Check notarization status
spctl -a -vv -t install build/MacRadio-1.0.0.dmg

# Should output: "accepted" if successful
```

## Troubleshooting

### Code Signing Issues

- Ensure you have a "Developer ID Application" certificate (not "Apple Development")
- Check certificate in Keychain Access
- Verify Team ID matches in exportOptions.plist

### Notarization Failures

- Check notarization logs: `xcrun notarytool log [submission-id] --keychain-profile AC_PASSWORD`
- Common issues:
  - Missing entitlements
  - Hardened runtime not enabled
  - Code signing errors

### Hardened Runtime

Ensure Hardened Runtime is enabled in Xcode:
1. Select project → MacRadio target
2. Signing & Capabilities
3. Enable "Hardened Runtime"
4. Add exceptions if needed (e.g., JIT, debugging)

## Distribution

Once notarized, the DMG is ready for distribution. Users can:
1. Download the DMG
2. Open it (macOS will verify notarization automatically)
3. Drag the app to Applications
4. Run without Gatekeeper warnings

## Resources

- [Apple Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/documentation/security/code_signing_services)

