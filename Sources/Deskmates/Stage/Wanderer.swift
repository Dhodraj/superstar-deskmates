import AppKit

/// Walks a character about its screen and rests between trips.
///
/// This is the stage's own behaviour, not a job. A job decides how a character
/// feels; the wanderer decides where it stands.
final class Wanderer {
    private enum State {
        case resting(until: Date)
        case walking(toX: CGFloat)
    }

    /// Where the other characters are standing, so this one does not walk
    /// through them. Supplied by the stage, which is the only thing that knows.
    var neighbours: () -> [NSRect] = { [] }
    /// Called when a walk ends, so the stage can remember the new position.
    var onArrived: () -> Void = {}

    private weak var panel: CharacterPanel?
    private var state: State = .resting(until: .distantPast)
    private var timer: Timer?
    private var paused = false
    /// Where the character is, in fractions of a point.
    ///
    /// AppKit rounds a window origin to whole points. At a walking pace one
    /// tick moves less than a point, so reading the position back from the
    /// window each tick threw the step away and nothing ever moved.
    private var x: CGFloat = 0

    /// Points per second. Slow enough to read as a stroll at this sprite size.
    private let speed: CGFloat = 26
    /// Gap kept between characters.
    private let clearance: CGFloat = 8
    private let tick: TimeInterval = 1.0 / 30

    init(panel: CharacterPanel) {
        self.panel = panel
    }

    func start() {
        x = panel?.frame.minX ?? 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] _ in
            self?.step()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Held while the user drags the character, so it does not fight the mouse.
    func pause() {
        paused = true
    }

    func resume() {
        paused = false
        x = panel?.frame.minX ?? x
        state = .resting(until: Date().addingTimeInterval(1))
    }

    /// True when the next step would put this character on top of another.
    private func blocked(panel: CharacterPanel, movingTo nextX: CGFloat) -> Bool {
        let next = NSRect(
            x: nextX - clearance,
            y: panel.frame.minY,
            width: panel.frame.width + clearance * 2,
            height: panel.frame.height
        )
        return neighbours().contains { $0.intersects(next) }
    }

    private func step() {
        guard !paused, let panel, let bounds = (panel.screen ?? NSScreen.main)?.visibleFrame else { return }

        switch state {
        case .resting(let until):
            guard Date() >= until else { return }
            let lowest = bounds.minX
            let highest = bounds.maxX - panel.frame.width
            guard highest > lowest else { return }
            x = panel.frame.minX
            state = .walking(toX: CGFloat.random(in: lowest...highest))
            panel.spriteView.play("walk")

        case .walking(let targetX):
            let remaining = targetX - x
            if abs(remaining) <= speed * tick {
                x = targetX
                panel.setFrameOrigin(NSPoint(x: x.rounded(), y: panel.frame.minY))
                state = .resting(until: Date().addingTimeInterval(.random(in: 3...12)))
                panel.spriteView.play("idle")
                onArrived()
                return
            }
            let stepX = remaining > 0 ? speed * tick : -speed * tick
            if blocked(panel: panel, movingTo: x + stepX) {
                state = .resting(until: Date().addingTimeInterval(.random(in: 1...4)))
                panel.spriteView.play("idle")
                onArrived()
                return
            }
            x += stepX
            panel.spriteView.facingLeft = remaining < 0
            panel.setFrameOrigin(NSPoint(x: x.rounded(), y: panel.frame.minY))
        }
    }
}
