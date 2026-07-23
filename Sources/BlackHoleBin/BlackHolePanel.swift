import AppKit

@MainActor
final class BlackHolePanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        level = UserDefaults.standard.bool(forKey: Defaults.alwaysOnTop) ? .floating : .normal
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func restoreOrPlaceAtDefaultPosition() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Defaults.hasSavedPosition) {
            let origin = NSPoint(
                x: defaults.double(forKey: Defaults.windowOriginX),
                y: defaults.double(forKey: Defaults.windowOriginY)
            )
            setFrameOrigin(constrainedOrigin(origin))
            return
        }

        guard let screen = NSScreen.main else {
            center()
            return
        }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.maxX - frame.width - 22,
            y: visible.minY + 22
        )
        setFrameOrigin(origin)
    }

    func savePosition() {
        let defaults = UserDefaults.standard
        defaults.set(frame.origin.x, forKey: Defaults.windowOriginX)
        defaults.set(frame.origin.y, forKey: Defaults.windowOriginY)
        defaults.set(true, forKey: Defaults.hasSavedPosition)
    }

    private func constrainedOrigin(_ proposed: NSPoint) -> NSPoint {
        let screen = NSScreen.screens.first { $0.visibleFrame.intersects(NSRect(origin: proposed, size: frame.size)) }
            ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return proposed }
        return NSPoint(
            x: min(max(proposed.x, visible.minX - frame.width * 0.45), visible.maxX - frame.width * 0.55),
            y: min(max(proposed.y, visible.minY - frame.height * 0.35), visible.maxY - frame.height * 0.65)
        )
    }
}
