import Foundation

/// What survives a restart: who is on screen, and where each one stood.
struct Settings: Codable {
    struct Position: Codable {
        var x: Double
        var y: Double
    }

    /// Characters currently on screen, in the order they were brought out.
    var active: [String] = []
    var positions: [String: Position] = [:]

    static let maxOnScreen = 3

    private static let url: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Deskmates/settings.json")
    }()

    static func load() -> Settings {
        guard let data = try? Data(contentsOf: url),
              let settings = try? JSONDecoder().decode(Settings.self, from: data)
        else {
            return Settings()
        }
        return settings
    }

    func save() {
        let directory = Self.url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(self).write(to: Self.url, options: .atomic)
    }
}
