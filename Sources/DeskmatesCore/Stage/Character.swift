import AppKit

/// One character on screen: its art, its panel, and the walking it does between
/// jobs. A job attaches later and only sets the mood.
final class Character {
    let name: String
    let panel: CharacterPanel
    let view: SpriteView

    private let directory: URL
    private let scale: CGFloat
    /// What this character does, if anything does it yet.
    let job: Job?

    private var sheet: SpriteSheet
    private var wanderer: Wanderer?
    private var watcher: SheetWatcher?
    private var mood: Mood = .idle

    /// Where the other characters are standing. Set by the stage.
    var neighbours: () -> [NSRect] = { [] }
    /// Called when the character settles somewhere new.
    var onSettled: () -> Void = {}

    init(name: String, directory: URL, scale: CGFloat, job: Job?) throws {
        self.name = name
        self.directory = directory
        self.scale = scale
        self.job = job
        sheet = try SpriteSheet(directory: directory)
        view = SpriteView(sheet: sheet, scale: scale)
        panel = CharacterPanel(spriteView: view)
    }

    /// Brings the character out and starts everything that costs time.
    func wake(at position: NSPoint?, slot: Int) {
        if let position {
            panel.setFrameOrigin(position)
        } else {
            panel.placeOnScreen(slot: slot)
        }
        panel.orderFrontRegardless()

        let wanderer = Wanderer(panel: panel)
        wanderer.neighbours = { [weak self] in self?.neighbours() ?? [] }
        wanderer.onArrived = { [weak self] in self?.onSettled() }
        self.wanderer = wanderer
        view.onDragBegan = { wanderer.pause() }
        view.onDragEnded = { [weak self] in
            wanderer.resume()
            self?.onSettled()
        }
        // A click goes to the job when there is one. Otherwise the character
        // does its signature pose once, which is all it has to say.
        view.onTapped = { [weak self] in
            guard let self else { return }
            if let job = self.job {
                job.tapped()
            } else if let signature = self.sheet.signature {
                self.view.playOnce(signature)
            }
        }

        watcher = SheetWatcher(directory: directory) { [weak self] in self?.reloadArt() }

        view.start()
        wanderer.start()
        job?.start { [weak self] mood in self?.show(mood) }
    }

    /// Puts a mood on screen.
    ///
    /// `idle` is the only mood that wanders. Anything else holds the character
    /// still, because a character crossing the screen while it reports a
    /// warning reads as two things at once.
    private func show(_ mood: Mood) {
        switch mood {
        case .happy:
            view.playOnce(sheet.signature ?? Mood.happy.rawValue)
        case .idle:
            self.mood = .idle
            wanderer?.resume()
            view.play(Mood.idle.rawValue)
        default:
            self.mood = mood
            wanderer?.pause()
            view.play(mood.rawValue)
        }
    }

    /// Puts the character away. Nothing of it keeps running, which is what
    /// "characters sleep when hidden" has to mean to be worth saying.
    func sleep() {
        job?.stop()
        wanderer?.stop()
        wanderer = nil
        watcher = nil
        view.stop()
        panel.orderOut(nil)
    }

    var position: NSPoint {
        panel.frame.origin
    }

    private func reloadArt() {
        guard let fresh = try? SpriteSheet(directory: directory) else { return }
        sheet = fresh
        view.replace(sheet: fresh)
    }
}
