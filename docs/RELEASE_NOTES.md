# Release Notes v0.2.0 - Expanded Support & Map Editor
## 🚀 Features
*   **Generic ROM Support**: 
    *   Removed strict Game Code checks. Any GBA ROM can now be loaded.
    *   Added `assets/offsets.json` database for auto-configuring Map/Script pointers for known games (FireRed US/JP, Emerald).
    *   Added **Manual Offset Entry** in the Map tab for unknown games.
*   **Map Editor Improvements**:
    *   Added **Zoom & Pan** support using `InteractiveViewer`.
    *   Added **Tile Inspector**: Tap any tile to see its coordinates (and eventually properties).

# Release Notes v0.1.1 - Fixes & Infrastructure Update

## 📦 Critical Dependency Updates
*   **Flutter Rust Bridge**: Upgraded to `2.7.0` (from `2.0.0-dev.32`) to ensure compatibility with the latest Flutter SDK and resolve build macros issues.
*   **State Management**: `flutter_riverpod` and `riverpod_annotation` updated to `^2.6.0` to resolve version solving failures.
*   **UI Components**: `infinite_canvas` placeholder updated to valid version `^0.0.10`.
*   **Dart SDK**: Minimum SDK constraint bumped to `3.3.0` to support `inline-class` features required by the generated Rust bindings.

## 🛠 Internal Fixes
*   **Rust Backend**: 
    *   Resolved `unexpected_cfgs` warnings in `lib.rs`.
    *   Fixed unused import warnings in `state.rs` and `scripting.rs`.
    *   Corrected import paths in `state.rs` to properly reference `RomHeader`.
*   **Dart Frontend**:
    *   Fixed broken import paths in `rom_provider.dart`, `home_screen.dart`, and `script_editor_screen.dart` to point to the newly generated `package:gba_forge/src/rust/...` files.
    *   Restored `main.dart` to correctly initialize `RustLib` and launch the main `GbaForgeApp`.
    *   Verified widget tests pass with the new bindings.

## 🚀 Known Issues
*   **MacOS Build**: Requires a full Xcode installation (not just Command Line Tools) for signing and bundling. This is expected behavior for desktop builds on macOS. See `docs/MACOS_XCODE_SETUP.md` for detailed instructions.

## 📋 Next Steps
*   Run the full test suite on a machine with Xcode installed to verify native MacOS bundle generation.
*   Proceed with implementing the remaining visual editor features (Map Editor interactions).
