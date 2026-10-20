import AppKit
import ServiceManagement

/// Starting with the Mac, which only works for a real app bundle.
///
/// `SMAppService` registers the running application by its bundle identifier,
/// so a binary run straight out of `.build` has nothing to register. The menu
/// entry hides itself in that case rather than offering something that fails.
enum LaunchAtLogin {
    static var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    static var isOn: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns what the setting ended up as, which is not always what was
    /// asked for: macOS can refuse, or the user can override it in Settings.
    @discardableResult
    static func set(_ wanted: Bool) -> Bool {
        do {
            if wanted {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            FileHandle.standardError.write(
                "could not change login item: \(error.localizedDescription)\n".data(using: .utf8)!
            )
        }
        return isOn
    }
}
