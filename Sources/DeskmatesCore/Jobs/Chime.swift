import AppKit

/// A short sound for the moment a job turns.
///
/// A character in the corner of the screen is easy to miss, so the thing worth
/// knowing gets a sound as well as a pose. Only transitions ring: a build that
/// stays green and a session that keeps running say nothing.
enum Chime {
    /// A focus session ended.
    case finished
    /// You left the app you were working in.
    case drifted
    /// The build went red.
    case broke
    /// The build went green again.
    case fixed
    /// Today's spending crossed the line you set.
    case spending

    private var systemSound: String {
        switch self {
        case .finished: return "Glass"
        case .drifted: return "Tink"
        case .broke: return "Basso"
        case .fixed: return "Hero"
        case .spending: return "Submarine"
        }
    }

    /// `DESKMATES_SILENT` turns every sound off.
    static func ring(_ chime: Chime) {
        guard ProcessInfo.processInfo.environment["DESKMATES_SILENT"] == nil else { return }
        NSSound(named: chime.systemSound)?.play()
    }
}
