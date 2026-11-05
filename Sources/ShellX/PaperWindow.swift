import AppKit
import SwiftUI

final class PaperWindow: NSWindow {
    private var restoredFrame: NSRect?
    private var maximizedFrame: NSRect?
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        title = "ShellX"
        contentMinSize = NSSize(width: 420, height: 420)
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior.insert(.fullScreenPrimary)
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override func performClose(_ sender: Any?) { if attachedSheet == nil { close() } }
    override func performMiniaturize(_ sender: Any?) { miniaturize(sender) }
    func toggleDesktopMaximize() {
        guard !styleMask.contains(.fullScreen), let visible = screen?.visibleFrame else { return }
        let target: NSRect
        if let restoredFrame, let maximizedFrame, frame.equalTo(maximizedFrame) {
            var restored = restoredFrame
            restored.size.width = min(restored.width, visible.width)
            restored.size.height = min(restored.height, visible.height)
            restored.origin.x = min(max(restored.minX, visible.minX), visible.maxX - restored.width)
            restored.origin.y = min(max(restored.minY, visible.minY), visible.maxY - restored.height)
            target = restored
            self.restoredFrame = nil
            self.maximizedFrame = nil
        } else {
            restoredFrame = frame
            maximizedFrame = visible
            target = visible
        }
        setFrame(target, display: true, animate: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    }
}

final class PaperView: NSView {
    private let dragRegion = DragRegion()
    private var cursorTracking: WritingCursorTracking!
    private static let texture: NSImage? = {
        let shipped = Bundle.main.resourceURL?.appendingPathComponent("ShellX_ShellX.bundle")
        let resources = shipped.flatMap(Bundle.init(url:)) ?? Bundle.module
        return resources.url(forResource: "PaperTexture", withExtension: "png").flatMap(NSImage.init(contentsOf:))
    }()
    override var isFlipped: Bool { true }
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        addSubview(dragRegion)
        cursorTracking = WritingCursorTracking(view: self)
        setAccessibilityElement(false)
        setAccessibilityRole(.group)
        setAccessibilityLabel("ShellX 终端工作区")
    }
    required init?(coder: NSCoder) { nil }
    override func layout() {
        super.layout()
        dragRegion.frame = NSRect(x: 12, y: 0, width: max(0, bounds.width - 24), height: 28)
    }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
    override func draw(_ dirtyRect: NSRect) {
        let dark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        (dark ? NSColor(calibratedWhite: 0.105, alpha: 1) : NSColor(calibratedRed: 0.99, green: 0.987, blue: 0.975, alpha: 1)).setFill()
        bounds.fill()
        Self.texture?.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: dark ? 0.035 : 0.32)
    }
}

final class DragRegion: NSView, WritingCursorProviding {
    private var cursorTracking: WritingCursorTracking!
    private var isDragging = false
    var writingCursorRole: WritingCursorRole {
        if window?.styleMask.contains(.fullScreen) == true { return .standard }
        return isDragging ? .dragging : .drag
    }
    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(false)
        cursorTracking = WritingCursorTracking(view: self, activeWhenInactive: true)
    }
    required init?(coder: NSCoder) { nil }
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        guard let window = window as? PaperWindow, !window.styleMask.contains(.fullScreen) else { return }
        if event.clickCount == 2 { window.toggleDesktopMaximize(); return }
        isDragging = true
        WritingCursors.closedHand.push()
        defer {
            isDragging = false
            NSCursor.pop()
            WritingCursors.update(in: window, at: window.mouseLocationOutsideOfEventStream)
        }
        window.performDrag(with: event)
    }
}
