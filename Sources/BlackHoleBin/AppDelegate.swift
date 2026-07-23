import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let trashController = TrashController()
    private var panel: BlackHolePanel?
    private var statusItem: NSStatusItem?
    private weak var blackHoleView: BlackHoleView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            Defaults.alwaysOnTop: true,
            Defaults.reduceMotion: false
        ])

        let view = BlackHoleView(frame: NSRect(x: 0, y: 0, width: 264, height: 264))
        view.trashController = trashController
        view.onStatusChange = { [weak self] message, kind in
            self?.showStatus(message, kind: kind)
        }

        let panel = BlackHolePanel(contentRect: view.bounds)
        panel.contentView = view
        panel.restoreOrPlaceAtDefaultPosition()
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
        self.blackHoleView = view
        configureStatusItem()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: panel
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        panel?.savePosition()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "circle.hexagongrid.circle.fill",
            accessibilityDescription: "黑洞垃圾箱"
        )
        item.button?.toolTip = "黑洞垃圾箱"

        let menu = NSMenu()
        let title = NSMenuItem(title: "黑洞垃圾箱", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        let showItem = NSMenuItem(title: "显示黑洞", action: #selector(showBlackHole), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        let undoItem = NSMenuItem(title: "撤销上次投放", action: #selector(undoLastDrop), keyEquivalent: "z")
        undoItem.target = self
        undoItem.tag = 100
        menu.addItem(undoItem)

        let motionItem = NSMenuItem(title: "减少动态效果", action: #selector(toggleReducedMotion(_:)), keyEquivalent: "")
        motionItem.target = self
        motionItem.state = UserDefaults.standard.bool(forKey: Defaults.reduceMotion) ? .on : .off
        menu.addItem(motionItem)

        let topItem = NSMenuItem(title: "始终悬浮在窗口上方", action: #selector(toggleAlwaysOnTop(_:)), keyEquivalent: "")
        topItem.target = self
        topItem.state = UserDefaults.standard.bool(forKey: Defaults.alwaysOnTop) ? .on : .off
        menu.addItem(topItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
        updateUndoMenuItem()
    }

    private func showStatus(_ message: String, kind: StatusKind) {
        blackHoleView?.showToast(message, kind: kind)
        updateUndoMenuItem()
    }

    private func updateUndoMenuItem() {
        guard let undoItem = statusItem?.menu?.item(withTag: 100) else { return }
        undoItem.isEnabled = trashController.canUndo
    }

    @objc private func showBlackHole() {
        panel?.orderFrontRegardless()
    }

    @objc private func undoLastDrop() {
        trashController.undoLastBatch { [weak self] result in
            switch result {
            case .success(let count):
                self?.blackHoleView?.renderer.triggerSuccess()
                self?.showStatus("已恢复 \(count) 个项目", kind: .success)
            case .failure(let error):
                self?.blackHoleView?.renderer.triggerError()
                self?.showStatus(error.localizedDescription, kind: .error)
            }
        }
    }

    @objc private func toggleReducedMotion(_ item: NSMenuItem) {
        let enabled = item.state != .on
        item.state = enabled ? .on : .off
        UserDefaults.standard.set(enabled, forKey: Defaults.reduceMotion)
        blackHoleView?.renderer.reduceMotion = enabled
    }

    @objc private func toggleAlwaysOnTop(_ item: NSMenuItem) {
        let enabled = item.state != .on
        item.state = enabled ? .on : .off
        UserDefaults.standard.set(enabled, forKey: Defaults.alwaysOnTop)
        panel?.level = enabled ? .floating : .normal
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func windowDidMove() {
        panel?.savePosition()
    }
}

enum Defaults {
    static let windowOriginX = "BlackHoleBin.windowOriginX"
    static let windowOriginY = "BlackHoleBin.windowOriginY"
    static let hasSavedPosition = "BlackHoleBin.hasSavedPosition"
    static let reduceMotion = "BlackHoleBin.reduceMotion"
    static let alwaysOnTop = "BlackHoleBin.alwaysOnTop"
}
