import AppKit
import QuartzCore
import UniformTypeIdentifiers

enum StatusKind {
    case neutral
    case success
    case error
}

@MainActor
final class BlackHoleView: NSView {
    let renderer: BlackHoleWebRenderer
    weak var trashController: TrashController?
    var onStatusChange: ((String, StatusKind) -> Void)?

    private let dropHint = CATextLayer()
    private let toastBackground = CALayer()
    private let toastText = CATextLayer()
    private let attractionRingA = CAShapeLayer()
    private let attractionRingB = CAShapeLayer()
    private let legacyFileListType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
    private let systemDragPasteboard = NSPasteboard(name: .drag)
    private var pointerTrackingArea: NSTrackingArea?
    private var hoverTimer: Timer?
    private var isPointerHovering = false
    private var isFileDragHovering = false
    private var wasLeftButtonDown = false
    private var pressStartedInsideBlackHole = false
    private var pendingDraggedURLs: [URL] = []
    private var lastDragPoint = CGPoint(x: 132, y: 132)
    private var isProcessingDrop = false

    override init(frame frameRect: NSRect) {
        renderer = BlackHoleWebRenderer()
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.isOpaque = false
        renderer.webView.frame = bounds
        renderer.webView.autoresizingMask = [.width, .height]
        addSubview(renderer.webView)
        registerForDraggedTypes([.fileURL, legacyFileListType])
        configureOverlayLayers()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        hoverTimer?.invalidate()
        hoverTimer = nil
        guard let window else { return }
        window.acceptsMouseMovedEvents = true
        hoverTimer = Timer.scheduledTimer(
            timeInterval: 1.0 / 30.0,
            target: self,
            selector: #selector(pollPointerHover),
            userInfo: nil,
            repeats: true
        )
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let pointerTrackingArea {
            removeTrackingArea(pointerTrackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        pointerTrackingArea = area
    }

    private func configureOverlayLayers() {
        guard let root = layer else { return }
        root.masksToBounds = false

        dropHint.string = "松手，送入黑洞"
        dropHint.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        dropHint.fontSize = 13
        dropHint.foregroundColor = NSColor.white.withAlphaComponent(0.94).cgColor
        dropHint.alignmentMode = .center
        dropHint.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        dropHint.frame = CGRect(x: 42, y: 18, width: bounds.width - 84, height: 21)
        dropHint.opacity = 0
        dropHint.zPosition = 220
        root.addSublayer(dropHint)

        toastBackground.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
        toastBackground.cornerRadius = 13
        toastBackground.frame = CGRect(x: 23, y: 10, width: bounds.width - 46, height: 32)
        toastBackground.opacity = 0
        toastBackground.zPosition = 240
        root.addSublayer(toastBackground)

        toastText.font = NSFont.systemFont(ofSize: 12.5, weight: .medium)
        toastText.fontSize = 12.5
        toastText.foregroundColor = NSColor.white.cgColor
        toastText.alignmentMode = .center
        toastText.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        toastText.frame = CGRect(x: 8, y: 7, width: toastBackground.bounds.width - 16, height: 18)
        toastBackground.addSublayer(toastText)

        configureAttractionRing(attractionRingA)
        configureAttractionRing(attractionRingB)
        root.addSublayer(attractionRingA)
        root.addSublayer(attractionRingB)
        updateAttractionRingFrames()
    }

    override func layout() {
        super.layout()
        renderer.webView.frame = bounds
        dropHint.frame = CGRect(x: 42, y: 18, width: bounds.width - 84, height: 21)
        toastBackground.frame = CGRect(x: 23, y: 10, width: bounds.width - 46, height: 32)
        toastText.frame = CGRect(x: 8, y: 7, width: toastBackground.bounds.width - 16, height: 18)
        updateAttractionRingFrames()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let operation = preferredDragOperation(for: sender)
        guard !isProcessingDrop, canAcceptFileDrag(sender), !operation.isEmpty else { return [] }
        isFileDragHovering = true
        renderer.hoverTarget = 1
        updateDragPoint(sender)
        setAttractionActive(true)
        setDropHint(visible: true)
        return operation
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let operation = preferredDragOperation(for: sender)
        guard !isProcessingDrop, canAcceptFileDrag(sender), !operation.isEmpty else { return [] }
        isFileDragHovering = true
        renderer.hoverTarget = 1
        updateDragPoint(sender)
        if attractionRingA.animation(forKey: "inward") == nil {
            setAttractionActive(true)
        }
        return operation
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isFileDragHovering = false
        restorePointerHoverState()
        setDropHint(visible: false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        canAcceptFileDrag(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = draggedFileURLs(from: sender)
        updateDragPoint(sender)
        return acceptDroppedURLs(urls)
    }

    @discardableResult
    func acceptDroppedURLs(_ urls: [URL]) -> Bool {
        guard
            !isProcessingDrop,
            !urls.isEmpty,
            let trashController
        else {
            return false
        }

        isProcessingDrop = true
        wasLeftButtonDown = false
        pressStartedInsideBlackHole = false
        pendingDraggedURLs = []
        isFileDragHovering = false
        renderer.hoverTarget = 1
        setDropHint(visible: false)
        setAttractionActive(false)
        playSuctionRings()
        renderer.triggerSuction()
        animateIconsIntoHorizon(for: urls, from: lastDragPoint)

        let animationDelay = UserDefaults.standard.bool(forKey: Defaults.reduceMotion) ? 0.16 : 0.88
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) { [weak self] in
            guard let self else { return }
            trashController.recycle(urls) { [weak self] result in
                guard let self else { return }
                isProcessingDrop = false
                renderer.hoverTarget = 0
                switch result {
                case .success(let count):
                    renderer.triggerSuccess()
                    onStatusChange?("已送入废纸篓 · \(count) 个项目", .success)
                case .failure(let error):
                    renderer.triggerError()
                    onStatusChange?("投放失败：\(error.localizedDescription)", .error)
                }
            }
        }

        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        isFileDragHovering = false
        if !isProcessingDrop {
            restorePointerHoverState()
        }
    }

    override func mouseEntered(with event: NSEvent) {
        isPointerHovering = true
        guard !isProcessingDrop, !isFileDragHovering else { return }
        renderer.hoverTarget = 0.48
        updatePointerPosition(convert(event.locationInWindow, from: nil))
        setAttractionActive(true)
    }

    override func mouseMoved(with event: NSEvent) {
        isPointerHovering = true
        guard !isProcessingDrop, !isFileDragHovering else { return }
        renderer.hoverTarget = 0.48
        updatePointerPosition(convert(event.locationInWindow, from: nil))
        if attractionRingA.animation(forKey: "inward") == nil {
            setAttractionActive(true)
        }
    }

    override func mouseExited(with event: NSEvent) {
        isPointerHovering = false
        guard !isFileDragHovering, !isProcessingDrop else { return }
        renderer.hoverTarget = 0
        renderer.dragVector = .zero
        setAttractionActive(false)
    }

    @objc private func pollPointerHover() {
        guard let window, !isProcessingDrop else { return }
        let screenPoint = NSEvent.mouseLocation
        let isInside = window.frame.contains(screenPoint)
        let leftButtonDown = NSEvent.pressedMouseButtons & 1 != 0

        if leftButtonDown, !wasLeftButtonDown {
            pressStartedInsideBlackHole = isInside
            pendingDraggedURLs = []
        }

        if leftButtonDown, !pressStartedInsideBlackHole {
            let urls = fileURLs(from: systemDragPasteboard)
            if !urls.isEmpty {
                pendingDraggedURLs = urls
                if isInside {
                    isFileDragHovering = true
                    setDropHint(visible: true)
                }
            }
        }

        if !leftButtonDown, wasLeftButtonDown {
            let releasedURLs = pendingDraggedURLs
            let shouldAcceptFallback = (
                !pressStartedInsideBlackHole
                && isInside
                && !releasedURLs.isEmpty
            )

            pendingDraggedURLs = []
            pressStartedInsideBlackHole = false
            isFileDragHovering = false
            setDropHint(visible: false)
            wasLeftButtonDown = false

            if shouldAcceptFallback {
                let pointInWindow = window.convertPoint(fromScreen: screenPoint)
                lastDragPoint = convert(pointInWindow, from: nil)
                _ = acceptDroppedURLs(releasedURLs)
                return
            }
        } else {
            wasLeftButtonDown = leftButtonDown
        }

        guard isInside else {
            if isPointerHovering {
                isPointerHovering = false
                guard !isFileDragHovering else { return }
                renderer.hoverTarget = 0
                renderer.dragVector = .zero
                setAttractionActive(false)
            }
            return
        }

        let pointInWindow = window.convertPoint(fromScreen: screenPoint)
        let point = convert(pointInWindow, from: nil)
        isPointerHovering = true
        updatePointerPosition(point)

        let target: Float = (isFileDragHovering || leftButtonDown) ? 1 : 0.48
        if renderer.hoverTarget != target {
            renderer.hoverTarget = target
        }
        if attractionRingA.animation(forKey: "inward") == nil {
            setAttractionActive(true)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            previewSuction()
            showToast("预览：文件会螺旋吸入黑洞", kind: .neutral)
        } else {
            window?.performDrag(with: event)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let undo = NSMenuItem(title: "撤销上次投放", action: #selector(undoLastDrop), keyEquivalent: "")
        undo.target = self
        undo.isEnabled = trashController?.canUndo == true
        menu.addItem(undo)
        menu.addItem(.separator())

        let reduce = NSMenuItem(title: "减少动态效果", action: #selector(toggleReducedMotion(_:)), keyEquivalent: "")
        reduce.target = self
        reduce.state = renderer.reduceMotion ? .on : .off
        menu.addItem(reduce)

        let quit = NSMenuItem(title: "退出黑洞垃圾箱", action: #selector(quitApplication), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    func showToast(_ message: String, kind: StatusKind) {
        toastText.string = message
        switch kind {
        case .neutral:
            toastBackground.backgroundColor = NSColor.black.withAlphaComponent(0.74).cgColor
        case .success:
            toastBackground.backgroundColor = NSColor(calibratedRed: 0.05, green: 0.28, blue: 0.20, alpha: 0.88).cgColor
        case .error:
            toastBackground.backgroundColor = NSColor(calibratedRed: 0.42, green: 0.07, blue: 0.05, alpha: 0.90).cgColor
        }

        toastBackground.removeAllAnimations()
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0, 1, 1, 0]
        animation.keyTimes = [0, 0.10, 0.76, 1]
        animation.duration = kind == .error ? 3.8 : 3.0
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeIn)
        ]
        toastBackground.add(animation, forKey: "toast")
    }

    private func updateDragPoint(_ sender: NSDraggingInfo) {
        let point = convert(sender.draggingLocation, from: nil)
        lastDragPoint = point
        updatePointerPosition(point)
    }

    private func updatePointerPosition(_ point: CGPoint) {
        let normalized = SIMD2<Float>(
            Float((point.x / bounds.width - 0.5) * 2),
            Float((point.y / bounds.height - 0.5) * 2)
        )
        renderer.dragVector = normalized
    }

    private func canAcceptFileDrag(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        if pasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) {
            return true
        }
        return pasteboard.availableType(from: [.fileURL, legacyFileListType]) != nil
    }

    private func preferredDragOperation(for sender: NSDraggingInfo) -> NSDragOperation {
        let offered = sender.draggingSourceOperationMask
        if offered.contains(.move) {
            return .move
        }
        if offered.contains(.copy) {
            return .copy
        }
        if offered.contains(.generic) {
            return .generic
        }
        return []
    }

    private func draggedFileURLs(from sender: NSDraggingInfo) -> [URL] {
        fileURLs(from: sender.draggingPasteboard)
    }

    private func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        var urls = (
            pasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            ) as? [NSURL]
        )?.map { $0 as URL } ?? []

        if urls.isEmpty {
            urls = pasteboard.pasteboardItems?.compactMap { item in
                guard
                    let value = item.string(forType: .fileURL),
                    let url = URL(string: value),
                    url.isFileURL
                else {
                    return nil
                }
                return url
            } ?? []
        }

        if
            urls.isEmpty,
            let paths = pasteboard.propertyList(forType: legacyFileListType) as? [String]
        {
            urls = paths.map(URL.init(fileURLWithPath:))
        }

        var seenPaths = Set<String>()
        return urls.filter { url in
            guard url.isFileURL else { return false }
            let path = url.standardizedFileURL.path
            return seenPaths.insert(path).inserted
        }
    }

    private func restorePointerHoverState() {
        if isPointerHovering {
            renderer.hoverTarget = 0.48
            setAttractionActive(true)
        } else {
            renderer.hoverTarget = 0
            renderer.dragVector = .zero
            setAttractionActive(false)
        }
    }

    private func setDropHint(visible: Bool) {
        dropHint.removeAllAnimations()
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = dropHint.presentation()?.opacity ?? dropHint.opacity
        fade.toValue = visible ? 1 : 0
        fade.duration = 0.16
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
        dropHint.opacity = visible ? 1 : 0
        dropHint.add(fade, forKey: "fade")
    }

    private func configureAttractionRing(_ ring: CAShapeLayer) {
        ring.fillColor = NSColor.clear.cgColor
        ring.strokeColor = NSColor(
            calibratedRed: 1.0,
            green: 0.78,
            blue: 0.42,
            alpha: 0.92
        ).cgColor
        ring.lineWidth = 2
        ring.lineDashPattern = [8, 11]
        ring.lineCap = .round
        ring.shadowColor = NSColor(
            calibratedRed: 1.0,
            green: 0.61,
            blue: 0.20,
            alpha: 1
        ).cgColor
        ring.shadowOpacity = 0.85
        ring.shadowRadius = 7
        ring.shadowOffset = .zero
        ring.opacity = 0
        ring.zPosition = 180
    }

    private func updateAttractionRingFrames() {
        let diameter = min(bounds.width, bounds.height) * 0.72
        let rect = CGRect(
            x: bounds.midX - diameter / 2,
            y: bounds.midY - diameter / 2,
            width: diameter,
            height: diameter
        )
        for ring in [attractionRingA, attractionRingB] {
            ring.frame = bounds
            ring.path = CGPath(ellipseIn: rect, transform: nil)
        }
    }

    private func setAttractionActive(_ active: Bool) {
        for ring in [attractionRingA, attractionRingB] {
            ring.removeAllAnimations()
            ring.opacity = 0
        }
        guard active, !renderer.reduceMotion else { return }

        addInwardRingAnimation(to: attractionRingA, delay: 0)
        addInwardRingAnimation(to: attractionRingB, delay: 0.42)
    }

    private func addInwardRingAnimation(to ring: CAShapeLayer, delay: CFTimeInterval) {
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.12
        scale.toValue = 0.26

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [0, 0.92, 0.76, 0]
        opacity.keyTimes = [0, 0.18, 0.70, 1]

        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = -CGFloat.pi

        let group = CAAnimationGroup()
        group.animations = [scale, opacity, rotation]
        group.duration = 0.84
        group.beginTime = CACurrentMediaTime() + delay
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeIn)
        ring.add(group, forKey: "inward")
    }

    private func playSuctionRings() {
        guard !renderer.reduceMotion else { return }
        for (index, ring) in [attractionRingA, attractionRingB].enumerated() {
            ring.removeAllAnimations()

            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1.18
            scale.toValue = 0.08

            let opacity = CAKeyframeAnimation(keyPath: "opacity")
            opacity.values = [0, 1, 0.88, 0]
            opacity.keyTimes = [0, 0.14, 0.74, 1]

            let rotation = CABasicAnimation(keyPath: "transform.rotation")
            rotation.fromValue = 0
            rotation.toValue = -CGFloat.pi * 1.5

            let group = CAAnimationGroup()
            group.animations = [scale, opacity, rotation]
            group.duration = 0.78
            group.beginTime = CACurrentMediaTime() + Double(index) * 0.10
            group.timingFunction = CAMediaTimingFunction(name: .easeIn)
            ring.add(group, forKey: "suction")
        }
    }

    private func previewSuction() {
        renderer.hoverTarget = 1
        renderer.triggerSuction()
        playSuctionRings()

        if let image = NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil) {
            animateIconIntoHorizon(
                image,
                from: CGPoint(x: bounds.maxX - 42, y: bounds.maxY - 46),
                index: 0
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.92) { [weak self] in
            self?.renderer.hoverTarget = 0
        }
    }

    private func animateIconsIntoHorizon(for urls: [URL], from startPoint: CGPoint) {
        for (index, url) in urls.prefix(7).enumerated() {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            animateIconIntoHorizon(icon, from: startPoint, index: index)
        }
    }

    private func animateIconIntoHorizon(_ icon: NSImage, from startPoint: CGPoint, index: Int) {
        guard let root = layer else { return }
        let reducedMotion = UserDefaults.standard.bool(forKey: Defaults.reduceMotion)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let iconSize: CGFloat = reducedMotion ? 46 : 60
        icon.size = NSSize(width: iconSize, height: iconSize)
        guard let image = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let iconLayer = CALayer()
        iconLayer.contents = image
        iconLayer.contentsGravity = .resizeAspect
        iconLayer.minificationFilter = .trilinear
        iconLayer.bounds = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        iconLayer.position = CGPoint(
            x: startPoint.x + CGFloat(index % 3 - 1) * 10,
            y: startPoint.y + CGFloat(index / 3) * 8
        )
        iconLayer.shadowColor = NSColor.black.cgColor
        iconLayer.shadowOpacity = 0.70
        iconLayer.shadowRadius = 9
        iconLayer.shadowOffset = .zero
        iconLayer.zPosition = 200
        root.addSublayer(iconLayer)

        let delay = Double(index) * 0.055
        let duration = reducedMotion ? 0.16 : 0.82
        let position = CAKeyframeAnimation(keyPath: "position")
        let path = CGMutablePath()
        path.move(to: iconLayer.position)

        let dx = iconLayer.position.x - center.x
        let dy = iconLayer.position.y - center.y
        let initialRadius = max(hypot(dx, dy), 34)
        let initialAngle = atan2(dy, dx)
        let steps = reducedMotion ? 3 : 36

        for step in 1...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let eased = 1 - pow(1 - t, 2.15)
            let radius = initialRadius * (1 - eased) + 1.5 * eased
            let turns = reducedMotion ? 0.12 : 1.75
            let angle = initialAngle + CGFloat.pi * 2 * turns * t
            path.addLine(to: CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            ))
        }

        position.path = path
        position.duration = duration
        position.beginTime = CACurrentMediaTime() + delay
        position.timingFunction = CAMediaTimingFunction(name: .easeIn)
        position.fillMode = .both
        position.isRemovedOnCompletion = false

        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [1.08, 0.92, 0.42, 0.025]
        scale.keyTimes = [0, 0.30, 0.72, 1]
        scale.duration = duration
        scale.beginTime = position.beginTime
        scale.timingFunction = CAMediaTimingFunction(name: .easeIn)
        scale.fillMode = .both
        scale.isRemovedOnCompletion = false

        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 3.5
        rotation.duration = duration
        rotation.beginTime = position.beginTime
        rotation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        rotation.fillMode = .both
        rotation.isRemovedOnCompletion = false

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [1, 1, 0.88, 0]
        opacity.keyTimes = [0, 0.58, 0.82, 1]
        opacity.duration = duration
        opacity.beginTime = position.beginTime
        opacity.fillMode = .both
        opacity.isRemovedOnCompletion = false

        iconLayer.add(position, forKey: "position")
        iconLayer.add(scale, forKey: "scale")
        iconLayer.add(rotation, forKey: "rotation")
        iconLayer.add(opacity, forKey: "opacity")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + duration + 0.08) {
            iconLayer.removeFromSuperlayer()
        }
    }

    @objc private func undoLastDrop() {
        trashController?.undoLastBatch { [weak self] result in
            switch result {
            case .success(let count):
                self?.renderer.triggerSuccess()
                self?.onStatusChange?("已恢复 \(count) 个项目", .success)
            case .failure(let error):
                self?.renderer.triggerError()
                self?.onStatusChange?(error.localizedDescription, .error)
            }
        }
    }

    @objc private func toggleReducedMotion(_ item: NSMenuItem) {
        renderer.reduceMotion.toggle()
        item.state = renderer.reduceMotion ? .on : .off
        UserDefaults.standard.set(renderer.reduceMotion, forKey: Defaults.reduceMotion)
    }

    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
}
