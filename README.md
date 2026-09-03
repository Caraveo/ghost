# 👻 Ghost

**A standalone desktop shell. Not a terminal. Not a TUI. A real native app.**

[![Rust](https://img.shields.io/badge/Rust-1.70+-orange)](https://rust-lang.org)
[![egui](https://img.shields.io/badge/egui-0.29-blue)](https://github.com/emilk/egui)
[![License](https://img.shields.io/badge/license-MIT-green)]()

---

Ghost is a self-contained desktop application that lets you run system commands
in a graphical interface. It does not run inside a terminal — it opens its own
window with panels, tabs, themes, and visual controls.

## ✨ Features

- **80+ built-in commands** — `ls`, `cp`, `mv`, `grep`, `find`, `tar`, `curl`, `calc`, `md5`, and more
- **Natural language aliases** — `list`, `copy`, `move`, `remove`, `print`, `spill`, `name`
- **Full PTY support** — interactive TUI apps like `opencode`, `grok`, `grid` run inline without freezing
- **Tabbed interface** — `Ctrl+T` for new tabs, commands open in their own tab
- **5 themes** — DarkCyan, Matrix, Solarized, Gruvbox, Light
- **Safety checks** — destructive commands ask confirmation with file listings
- **Git status** — branch and dirty flag in the status bar
- **Drag & drop** — drop files from Finder into the input
- **Clickable URLs** — https:// links in output are clickable
- **Tab completion** — scans `$PATH` + builtins
- **Command history** — Up/Down navigation
- **Code editor** — `edit file.rs` opens a built-in editor with syntax highlighting
- **Settings panel** — theme, font size, terminal size, environment variables, PATH viewer
- **Right-click to copy** — output to clipboard with `*copied*` feedback

## 🚀 Quick Start

```bash
# Build
cargo build --release

# Create macOS .app bundle
./build_app.sh

# Run
open Ghost.app
```

## ⌨️ Keybindings

| Key | Action |
|-----|--------|
| `Enter` | Execute command |
| `Tab` | Auto-complete |
| `↑/↓` | History navigation |
| `Ctrl+T` | New tab |
| `Ctrl+L` | Clear output |
| `Ctrl+C` | Interrupt / Clear input |
| `Ctrl+D` | Quit |
| `Ctrl+H` | Toggle help |
| `Esc` | Cancel / Close editor / Quit |
| `Ctrl+S` | Save file (in editor) |

## 📦 Shell Syntax

```
cmd1 | cmd2          Pipe output
cmd > file           Redirect to file
cmd >> file          Append to file
cmd < file           Read from file
cmd1 && cmd2         Run if previous succeeds
cmd1 || cmd2         Run if previous fails
cmd &                Run in background
$VAR / ${VAR}        Environment variable
```

## 🛠 Built With

- [Rust](https://rust-lang.org) — language
- [egui](https://github.com/emilk/egui) — GUI framework
- [portable-pty](https://crates.io/crates/portable-pty) — PTY for interactive commands
- [vt100](https://crates.io/crates/vt100) — terminal screen parser
- [syntect](https://crates.io/crates/syntect) — syntax highlighting for the code editor

## 📂 Project Structure

```
ghost/
├── src/
│   ├── main.rs        — app entry, command execution loop
│   ├── app.rs         — app state, tabs, themes
│   ├── gui.rs         — all UI rendering
│   ├── pty.rs         — PTY session management
│   ├── editor.rs      — code editor with syntax highlighting
│   ├── executor.rs    — command pipeline execution
│   ├── parser.rs      — shell syntax parser
│   ├── builtins.rs    — built-in commands
│   ├── safety.rs      — destructive command detection
│   ├── completion.rs  — tab completion engine
│   ├── fileops.rs     — file operations
│   ├── network.rs     — network commands (seek, curl, ftp)
│   ├── textproc.rs    — text processing (grep, sed, sort...)
│   └── sysutils.rs    — system utilities
├── Cargo.toml
├── build_app.sh       — macOS .app bundle builder
└── Ghost.app/         — built application
```

## License

MIT
