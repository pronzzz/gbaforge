# GBAForge

![Build Status](https://img.shields.io/github/actions/workflow/status/pronzzz/gbaforge/main.yml?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Rust](https://img.shields.io/badge/Rust-1.75+-000000?style=for-the-badge&logo=rust)

**GBAForge** is a cross-platform, "Hybrid-Native" ROM hacking suite designed for Pokémon FireRed (BPRE) and Emerald (BPEE). It merges the visual flexibility of **Flutter** with the high-performance binary manipulation of **Rust** to deliver a modern, safe, and powerful editing experience.

---

## 🚀 Key Features

### 🛠 Hybrid Architecture
*   **Frontend**: Built with **Flutter**, ensuring a pixel-perfect, responsive UI on Windows, macOS, and Linux.
*   **Backend**: Powered by **Rust**, guaranteeing memory safety and zero-cost abstractions for heavy binary tasks.

### 🎨 Visual Editors
*   **Map Preview**: Real-time rendering of GBA maps. Handles intricate metatile rendering, palettes, and LZ77 decompression instantly.
*   **Script Editor**: A visual node-based interface that disassembles raw XSE bytecode into a readable flow, making complex event scripting accessible.
*   **Space Management**: Intelligent background workers scan for free space (`0xFF`) and handle repointing automatically, preventing data corruption.

### 🛡 Safe & Secure
*   **Validation**: Automatic Game Code validation (BPRE/BPEE).
*   **Checksums**: Auto-calculation of ROM header checksums on save.
*   **Backup**: Non-destructive editing workflow.

---

## 🏗 Technology Stack

-   **UI Framework**: Flutter (Dart)
-   **Core Logic**: Rust (Systems Programming)
-   **FFI Bridge**: `flutter_rust_bridge` (Zero-copy communication)
-   **Parsing**: `binrw` (Declarative binary parsing)
-   **Compression**: Custom LZ77 (BIOS-compatible type 0x10)

---

## ⚡ Quick Start

### Prerequisites
1.  **Flutter SDK** (Latest Stable)
2.  **Rust Toolchain** (`rustup update`)
3.  **Codegen Tool**:
    ```bash
    cargo install flutter_rust_bridge_codegen
    ```

### Running Locally

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/pronzzz/gbaforge.git
    cd gbaforge
    ```

2.  **Generate Bindings**
    This step connects the Rust backend to the Flutter frontend.
    ```bash
    flutter_rust_bridge_codegen generate
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📚 Documentation

For a deep dive into the architecture, build process, and internal module details, please refer to the **[Development Guide](docs/DEVELOPMENT_GUIDE.md)**.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
