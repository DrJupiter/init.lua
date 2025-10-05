# Neovim Configuration - `init.lua`

Welcome to my Neovim configuration repository! This setup is designed to create an efficient, visually pleasing, and highly customizable development environment powered by Lua. This README outlines each configuration component for easy customization and reference.

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [File Structure](#file-structure)
- [Installation](#installation)
- [Configuration Details](#configuration-details)
  - [Key Mappings](#key-mappings)
  - [Plugin Management](#plugin-management)
  - [Color Scheme](#color-scheme)
  - [Syntax Highlighting with Treesitter](#syntax-highlighting-with-treesitter)
  - [Fuzzy Finder - Telescope](#fuzzy-finder---telescope)
  - [Language Server Protocol (LSP)](#language-server-protocol-lsp)
  - [Editor Settings](#editor-settings)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This configuration is a Lua-based setup for Neovim, leveraging powerful plugins and custom settings to improve development speed and ease. It includes syntax highlighting, fuzzy file finding, LSP support, and more.

## Features

- **Modern Plugin Management** with lazy loading
- **Enhanced Syntax Highlighting** using Treesitter
- **Language Server Protocol (LSP)** for code intelligence and diagnostics
- **Java, Kotlin, and Android Tooling** with dedicated language servers, debugging,
  and formatting integrations
- **File Navigation** with Telescope fuzzy finder
- **Custom Key Mappings** for improved workflow
- **Tailored Editor Settings** for readability and efficiency

---

## File Structure

- `init.lua`: Main configuration file that loads essential modules and settings.
- `remap.lua`: Custom key mappings for better navigation and efficiency.
- `lazy_init.lua`: Plugin management using lazy loading.
- `colors.lua`: Color scheme configurations for visual customization.
- `treesitter.lua`: Configuration for enhanced syntax highlighting via Treesitter.
- `telescope.lua`: Settings for the Telescope fuzzy finder.
- `lsp.lua`: Configurations for LSP, providing autocompletion and diagnostics.
- `set.lua`: Editor settings like indentation, line numbers, etc.

---

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/DrJupiter/init.lua.git ~/.config/nvim
   ```

2. **Install Plugin Manager** (assuming `lazy.nvim`):
   Follow the plugin manager’s installation instructions to ensure plugins load correctly.

3. **Install Plugins**:
   Open Neovim and run:
   ```vim
   :LazyInstall
   ```

4. **Verify Configuration**:
   Ensure all plugins and settings are working by restarting Neovim.

---

## Configuration Details

### Key Mappings

Custom key mappings are defined in `remap.lua`, offering efficient shortcuts and navigation aids. Some mappings include:

- **Leader Key**: Custom leader key for invoking plugins and commands.
- **File Operations**: Mappings for fast file management and buffer handling.

### Plugin Management

Plugins are managed in `lazy_init.lua`, utilizing lazy loading to optimize startup time and system resources. Key plugins include:

- **Telescope** for fuzzy finding
- **nvim-treesitter** for syntax parsing
- **nvim-lspconfig** for LSP integrations

### Color Scheme

`colors.lua` configures the editor’s theme, offering an aesthetically pleasing color scheme to reduce eye strain and enhance readability.

### Syntax Highlighting with Treesitter

Treesitter is configured in `treesitter.lua` to provide advanced syntax highlighting and parsing, making code easier to read and navigate.

### Fuzzy Finder - Telescope

Telescope settings in `telescope.lua` enable efficient searching for files, symbols, and text within projects. It includes features like:

- **File Search**: Quickly find files in the project directory
- **Symbol Search**: Jump to specific symbols in code

### Language Server Protocol (LSP)

The `lsp.lua` file manages Neovim’s LSP integrations, enabling IDE-like features such as autocompletion, diagnostics, and navigation. Supported languages and servers can be customized within this file.

#### Java & Android Development

This configuration ships with first-class support for Android projects:

- **Language Servers**: `jdtls` for Java, `kotlin_language_server` for Kotlin, and `android_language_server` for Android-specific XML and build tooling are configured through Neovim’s modern `vim.lsp` interface.
- **Tooling via Mason**: Debug adapters (`java-debug-adapter`, `java-test`) and formatters (`google-java-format`) are automatically installed alongside the language servers.
- **Syntax Highlighting**: Tree-sitter parsers for Java, Kotlin, and XML are ensured so Android source, Gradle build scripts, and manifests benefit from rich highlighting.
- **Formatting & Diagnostics**: Java buffers use Google’s style guide defaults, and LSP-powered diagnostics provide linting feedback across Java, Kotlin, and Android resources.

### Editor Settings

Basic editor settings in `set.lua` include:

- **Line Numbers**: Absolute and relative line numbering
- **Indentation**: Configured tab size and spaces
- **Search Behavior**: Case-insensitive searching

---

## Contributing

Contributions are welcome! Please open issues for bugs or feature requests, and feel free to submit pull requests with improvements.

---

## License

This configuration is open-source under the [MIT License](LICENSE).
