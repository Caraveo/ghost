import SwiftUI
import Cocoa

// MARK: - Settings Model

struct GhostSettings: Codable {
    var theme: String = "DarkCyan"
    var font_size: Double = 13.0
    var pty_cols: Int = 120
    var pty_rows: Int = 40
    var auto_switch: Bool = true
    var startup_msg: Bool = true
    var safety: Bool = true
}

func settingsPath() -> URL {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let dir = home.appendingPathComponent(".config/ghost")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("settings.json")
}

// MARK: - General Tab

struct GeneralTab: View {
    @State private var s = GhostSettings()

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { s.theme },
                    set: { s.theme = $0; persist() }
                )) {
                    Text("Dark Cyan").tag("DarkCyan")
                    Text("Matrix").tag("Matrix")
                    Text("Solarized").tag("Solarized")
                    Text("Gruvbox").tag("Gruvbox")
                    Text("Light").tag("Light")
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Font Size")
                    Slider(
                        value: Binding(
                            get: { s.font_size },
                            set: { s.font_size = $0; persist() }
                        ),
                        in: 9...20
                    )
                    Text(String(format: "%.0fpx", s.font_size))
                        .frame(width: 44, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            }

            Section("Terminal Emulation") {
                Text("The terminal grid automatically follows the window size.")
                    .foregroundColor(.secondary)
                Toggle("Auto-switch to new command tabs", isOn: Binding(
                    get: { s.auto_switch },
                    set: { s.auto_switch = $0; persist() }
                ))
            }

            Section("Behavior") {
                Toggle("Show startup message", isOn: Binding(
                    get: { s.startup_msg },
                    set: { s.startup_msg = $0; persist() }
                ))
                Toggle("Safety checks for destructive commands", isOn: Binding(
                    get: { s.safety },
                    set: { s.safety = $0; persist() }
                ))
            }
        }
        .formStyle(.grouped)
        .onAppear { load() }
    }

    func load() {
        if let data = try? Data(contentsOf: settingsPath()),
           let decoded = try? JSONDecoder().decode(GhostSettings.self, from: data) {
            s = decoded
        }
    }

    func persist() {
        if let data = try? JSONEncoder().encode(s) {
            try? data.write(to: settingsPath())
        }
    }
}

// MARK: - Environment Tab

struct EnvTab: View {
    let env: [(String, String)]

    init() {
        env = ProcessInfo.processInfo.environment
            .filter { $0.key != "?" }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        List(env, id: \.0) { key, value in
            HStack {
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.cyan)
                Text("=")
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundColor(.cyan)
            Text("Ghost Shell")
                .font(.title)
                .fontWeight(.bold)
            Text("v0.7.0")
                .foregroundColor(.secondary)
            Text("Native macOS shell with responsive terminal emulation")
                .foregroundColor(.secondary)
            VStack(spacing: 4) {
                Text("Ctrl+T  new tab")
                Text("Ctrl+L  clear")
                Text("Ctrl+H  help")
                Text("Ctrl+D  quit")
            }
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Main Settings View

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            EnvTab()
                .tabItem { Label("Environment", systemImage: "terminal") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 420)
    }
}

// MARK: - Menu Bar

import AppKit

var ghostMenuAction: Int32 = 0

@_cdecl("ghost_setup_menu")
func ghost_setup_menu() {
    DispatchQueue.main.async {
        guard let app = NSApp else { return }
        let mainMenu = NSMenu()

        // Ghost menu (app menu)
        let ghostMenu = NSMenuItem(title: "Ghost", action: nil, keyEquivalent: "")
        let ghostSubmenu = NSMenu(title: "Ghost")
        ghostSubmenu.addItem(withTitle: "About Ghost", action: #selector(NSApp.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        ghostSubmenu.addItem(NSMenuItem.separator())
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(GhostMenuTarget.showSettings), keyEquivalent: ",")
        settingsItem.target = GhostMenuTarget.shared
        ghostSubmenu.addItem(settingsItem)
        ghostSubmenu.addItem(NSMenuItem.separator())
        ghostSubmenu.addItem(withTitle: "Hide Ghost", action: #selector(NSApp.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApp.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        ghostSubmenu.addItem(hideOthers)
        ghostSubmenu.addItem(withTitle: "Show All", action: #selector(NSApp.unhideAllApplications(_:)), keyEquivalent: "")
        ghostSubmenu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit Ghost", action: #selector(GhostMenuTarget.quit), keyEquivalent: "q")
        quitItem.target = GhostMenuTarget.shared
        ghostSubmenu.addItem(quitItem)
        ghostMenu.submenu = ghostSubmenu
        mainMenu.addItem(ghostMenu)

        // File menu
        let fileMenu = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileSubmenu = NSMenu(title: "File")
        let newTabItem = NSMenuItem(title: "New Tab", action: #selector(GhostMenuTarget.newTab), keyEquivalent: "t")
        newTabItem.target = GhostMenuTarget.shared
        fileSubmenu.addItem(newTabItem)
        let closeTabItem = NSMenuItem(title: "Close Tab", action: #selector(GhostMenuTarget.closeTab), keyEquivalent: "w")
        closeTabItem.target = GhostMenuTarget.shared
        fileSubmenu.addItem(closeTabItem)
        fileSubmenu.addItem(NSMenuItem.separator())
        let clearItem = NSMenuItem(title: "Clear Output", action: #selector(GhostMenuTarget.clearOutput), keyEquivalent: "l")
        clearItem.target = GhostMenuTarget.shared
        fileSubmenu.addItem(clearItem)
        fileMenu.submenu = fileSubmenu
        mainMenu.addItem(fileMenu)

        // Edit menu
        let editMenu = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editSubmenu = NSMenu(title: "Edit")
        editSubmenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editSubmenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editSubmenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editSubmenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.submenu = editSubmenu
        mainMenu.addItem(editMenu)

        // View menu
        let viewMenu = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewSubmenu = NSMenu(title: "View")
        let helpItem = NSMenuItem(title: "Toggle Help", action: #selector(GhostMenuTarget.toggleHelp), keyEquivalent: "h")
        helpItem.target = GhostMenuTarget.shared
        helpItem.keyEquivalentModifierMask = [.command, .shift]
        viewSubmenu.addItem(helpItem)
        viewMenu.submenu = viewSubmenu
        mainMenu.addItem(viewMenu)

        // Window menu
        let windowMenu = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowSubmenu = NSMenu(title: "Window")
        windowSubmenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowSubmenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowSubmenu.addItem(NSMenuItem.separator())
        windowSubmenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApp.arrangeInFront(_:)), keyEquivalent: "")
        windowMenu.submenu = windowSubmenu
        mainMenu.addItem(windowMenu)

        app.mainMenu = mainMenu
    }
}

@_cdecl("ghost_consume_menu_action")
func ghost_consume_menu_action() -> Int32 {
    let a = ghostMenuAction
    ghostMenuAction = 0
    return a
}

class GhostMenuTarget: NSObject {
    static let shared = GhostMenuTarget()

    @objc func showSettings() {
        ghost_show_settings()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    @objc func newTab() {
        ghostMenuAction = 1
    }

    @objc func closeTab() {
        ghostMenuAction = 2;
    }

    @objc func clearOutput() {
        ghostMenuAction = 3
    }

    @objc func toggleHelp() {
        ghostMenuAction = 4
    }
}

// MARK: - FFI Entry Point

@_cdecl("ghost_show_settings")
func ghost_show_settings() {
    DispatchQueue.main.async {
        if let existing = NSApp.windows.first(where: { $0.title == "Ghost Settings" }) {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Ghost Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
