import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            let appearance = effectiveAppearance(for: SettingsManager.shared.settings.theme)
            NSApp.appearance = appearance
            for window in NSApp.windows {
                window.appearance = appearance
                window.invalidateShadow()
            }
            NSApp.activate(ignoringOtherApps: true)
            NSApp.keyWindow?.makeKey()
        }
    }
}

func effectiveAppearance(for theme: AppTheme) -> NSAppearance {
    switch theme {
    case .light: return NSAppearance(named: .aqua)!
    case .dark: return NSAppearance(named: .darkAqua)!
    case .system:
        NSApp.appearance = nil
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return isDark ? NSAppearance(named: .darkAqua)! : NSAppearance(named: .aqua)!
    }
}

func applyTheme(_ theme: AppTheme) {
    let appearance = effectiveAppearance(for: theme)
    NSApp.appearance = appearance
    DispatchQueue.main.async {
        for window in NSApp.windows {
            window.appearance = appearance
            window.invalidateShadow()
        }
    }
}

@main
struct StarListApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsManager = SettingsManager.shared

    var body: some Scene {
        WindowGroup("Github Star List") {
            StarListView(settingsManager: settingsManager)
                .environmentObject(settingsManager)
                .preferredColorScheme(settingsManager.settings.theme.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1000, height: 700)
        .defaultAppStorage(UserDefaults.standard)
        .onChange(of: settingsManager.settings.theme) { _, newTheme in
            applyTheme(newTheme)
        }

        Settings {
            SettingsView(settingsManager: settingsManager)
                .preferredColorScheme(settingsManager.settings.theme.colorScheme)
        }
        .onChange(of: settingsManager.settings.theme) { _, newTheme in
            applyTheme(newTheme)
        }
    }
}
