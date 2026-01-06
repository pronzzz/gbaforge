# macOS Development & Xcode Setup Guide

## Prerequisites

Building GBAForge for macOS requires a macOS environment with Xcode installed. The standard "Command Line Tools" are **insufficient** because Flutter requires the `xcodebuild` utility and signing capabilities provided by the full Xcode IDE.

### 1. Install Xcode
1.  Open the **Mac App Store** and search for **Xcode**.
2.  Install the latest version of Xcode.
3.  Once installed, open Xcode once to accept the license agreement and install additional components.

### 2. Configure Command Line Tools
Verify that your system is using the Xcode version of the compiler tools, not the standalone library.

Run the following command in your terminal:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### 3. Verify Installation
Check that `xcodebuild` is now available and properly linked:
```bash
xcodebuild -version
```
*Output should resemble:*
```text
Xcode 15.x
Build version ...
```

### 4. CocoaPods (Recommended)
Flutter MacOS apps often rely on CocoaPods for dependency management of native plugins. The most reliable way to install it is via Homebrew:
```bash
brew install cocoapods
```
(Alternatively, if you use a Ruby version manager like rbenv, you can use `gem install cocoapods`)

## Running GBAForge on macOS

Once Xcode is set up, you can run the application directly from the project root:

1.  **Generate Rust Bindings (If not already done)**:
    ```bash
    flutter_rust_bridge_codegen generate
    ```

2.  **Run the App**:
    ```bash
    flutter run -d macos
    ```

## Troubleshooting Common Issues

### "Unable to find utility 'xcodebuild'"
**Cause:** You are likely using the standalone Command Line Tools instead of the full Xcode app.
**Fix:** Ensure you have installed Xcode from the App Store and run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.

### Signing Issues
If you encounter code signing errors during build:
1.  Open `macos/Runner.xcworkspace` in Xcode.
2.  Select the **Runner** project in the navigator.
3.  Go to the **Signing & Capabilities** tab.
4.  Ensure a **Team** is selected (you can use your personal Apple ID for local development).
5.  Try running from Xcode (`Product > Run`) to verify the signing configuration.
