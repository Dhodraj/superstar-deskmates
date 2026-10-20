import AppKit
import IOKit.ps

/// Ajit's job. The fuel gauge.
///
/// He races, so the charge is the thing he watches. Helmet on while the Mac is
/// charging, hands up when it is nearly empty. Nothing leaves the machine and
/// nothing needs permission.
final class Battery: NSObject, Job {
    static let id = "battery"

    struct Reading: Equatable {
        var percent: Int
        var charging: Bool
        /// Minutes until empty, or until full while charging. Nil while the
        /// system is still working it out, which it does for a minute or two
        /// after a cable goes in.
        var minutes: Int?

        var summary: String {
            if charging {
                guard let minutes else { return "Battery \(percent)%, charging" }
                return "Battery \(percent)%, \(Reading.clock(minutes)) to full"
            }
            guard let minutes else { return "Battery \(percent)%" }
            return "Battery \(percent)%, \(Reading.clock(minutes)) left"
        }

        static func clock(_ minutes: Int) -> String {
            String(format: "%d:%02d", minutes / 60, minutes % 60)
        }
    }

    /// Below this he puts his hands up.
    private let lowPercent: Int
    private let interval: TimeInterval
    private let read: () -> Reading?

    private var ticker: Timer?
    private var emit: ((Mood) -> Void)?
    private var mood: Mood = .idle
    private(set) var reading: Reading?

    init(
        lowPercent: Int = Battery.lowFromEnvironment(),
        interval: TimeInterval = 30,
        read: @escaping () -> Reading? = Battery.readPowerSource
    ) {
        self.lowPercent = lowPercent
        self.interval = interval
        self.read = read
    }

    /// `DESKMATES_BATTERY_LOW` overrides the warning level.
    static func lowFromEnvironment() -> Int {
        guard let text = ProcessInfo.processInfo.environment["DESKMATES_BATTERY_LOW"],
              let value = Int(text), value > 0, value < 100
        else {
            return 20
        }
        return value
    }

    func start(_ emit: @escaping (Mood) -> Void) {
        self.emit = emit
        emit(.idle)
        refresh()
        ticker = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
    }

    func tapped() {
        refresh()
    }

    func menuItems() -> [NSMenuItem] {
        let item = NSMenuItem(
            title: reading?.summary ?? "No battery",
            action: nil,
            keyEquivalent: ""
        )
        item.isEnabled = false
        return [item]
    }

    func refresh() {
        reading = read()
        let wanted = Self.mood(for: reading, lowPercent: lowPercent)
        guard wanted != mood else { return }
        mood = wanted
        emit?(wanted)
    }

    /// A Mac with no battery reads as idle. Standing still is the honest
    /// answer when there is nothing to report.
    static func mood(for reading: Reading?, lowPercent: Int) -> Mood {
        guard let reading else { return .idle }
        if reading.charging { return .busy }
        return reading.percent <= lowPercent ? .alert : .idle
    }

    /// The one place that talks to the system.
    static func readPowerSource() -> Reading? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return nil
        }
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any],
                  let current = info[kIOPSCurrentCapacityKey as String] as? Int,
                  let maximum = info[kIOPSMaxCapacityKey as String] as? Int,
                  maximum > 0
            else { continue }

            let charging = (info[kIOPSIsChargingKey as String] as? Bool) ?? false
            let key = charging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
            let raw = info[key as String] as? Int
            // The system reports -1 while it is still estimating.
            let minutes = (raw ?? -1) >= 0 ? raw : nil

            return Reading(
                percent: Int((Double(current) / Double(maximum) * 100).rounded()),
                charging: charging,
                minutes: minutes
            )
        }
        return nil
    }
}
