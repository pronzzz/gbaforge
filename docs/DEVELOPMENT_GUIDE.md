# GBAForge Development Guide

This document provides a comprehensive technical overview of GBAForge. It is intended for developers who want to contribute to the project or understand the underlying architecture.

## 📂 Directory Structure

The project follows a "Hybrid-Native" structure, separating the UI from the core logic.

```
gbaforge/
├── lib/                    # CSS (Flutter/Dart Frontend)
│   ├── src/
│   │   ├── features/       # Feature-based organization (Editor, etc.)
│   │   │   └── editor/
│   │   │       ├── screens/    # e.g., HomeScreen, ScriptEditorScreen
│   │   │       └── providers/  # Riverpod State Management
│   │   └── rust/           # Generated Dart bindings for Rust
│   └── main.dart           # Application Entry Point
│
├── native/                 # Backend (Rust Core)
│   ├── src/
│   │   ├── api.rs          # FFI Interface (exposed to Flutter)
│   │   ├── compression.rs  # LZ77 Decompression Implementation
│   │   ├── graphics.rs     # Graphics Processing (BGR555 -> RGBA)
│   │   ├── scripting.rs    # XSE Bytecode Disassembler
│   │   ├── space_manager.rs # Free Space Finder & Repointing Logic
│   │   ├── state.rs        # Global State (RwLock<RomState>)
│   │   └── structures.rs   # Binary Data Structures (binrw)
│   └── Cargo.toml          # Rust Dependencies
│
├── test/                   # Flutter Widget Tests
└── .github/                # GitHub Actions Workflows
```

## 🏗 Architecture Details

### 1. The Bridge (`flutter_rust_bridge`)
We use `flutter_rust_bridge` (FRB) to handle communication between Dart and Rust.
-   **Rust Side**: Functions in `native/src/api.rs` are marked with `pub fn`. These function signatures are analyzed by the codegen tool.
-   **Dart Side**: Generated code in `lib/src/rust/` handles the FFI marshalling (converting primitive types, lists, and structs).
-   **Zero Copy**: Large buffers (like the rendered map image) use zero-copy transfer where possible to maintain 60 FPS performance.

### 2. ROM Parsing (`binrw`)
Instead of manually seeking to offsets (e.g., `rom[0xAC]`), we define Rust structs that map directly to the binary layout.
-   **`RomHeader`**: Checks the Game Code (BPRE/BPEE) to ensure safety.
-   **`MapHeader`**: Reads pointers to the map layout, events, and scripts.

### 3. Graphics Pipeline
GBA graphics are stored in a tiled, compressed format.
1.  **Decompression**: `compression.rs` implements a BIOS-compatible LZ77 algorithm.
2.  **Decoding**: `graphics.rs` converts 4bpp (4 bits/pixel) tile data into standard RGBA. It handles the GBA's 15-bit color space (BGR555).
3.  **Rendering**: `render_map_preview` assembles these tiles into a single image buffer, which Flutter displays using `Image.memory`.

### 4. Scripting Engine
The script editor visualizes the game's event logic.
-   **Disassembler**: `scripting.rs` reads the bytecode byte-by-byte. It identifies opcodes (e.g., `0x0F` for `msgbox`) and their parameters, constructing a `ScriptCommand` enum tree.
-   **Visualization**: The Flutter UI (`ScriptEditorScreen`) takes this list and renders it as a sequence of cards (mocking a node graph).

## 🧪 Testing

### Rust Tests
Unit tests are located in the `native/` directory. They verify the low-level logic.
```bash
cd native
cargo test
```
*   **Compression Tests**: Verify "round-trip" or known-output behavior for LZ77.
*   **Graphics Tests**: Ensure correct color math (avoiding overflows).
*   **Scripting Tests**: Verify that known bytecode sequences produce the correct AST.

### Flutter Tests
Widget tests verify the UI components.
```bash
flutter test
```

## 📦 Building for Release

The project is configured for automated builds via GitHub Actions.
-   **Windows**: `.exe` (MSVC)
-   **Linux**: AppImage or binary (GTK3)
-   **macOS**: `.app`/`.dmg` (Cocoa)

To build locally:
```bash
flutter build windows --release
# or
flutter build macos --release
# or
flutter build linux --release
```
