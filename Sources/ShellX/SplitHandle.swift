import AppKit
import SwiftUI

enum StudySplitAxis { case vertical, horizontal }

struct StudySplitHandle: NSViewRepresentable {
    var axis: StudySplitAxis = .vertical
    let topHeight: CGFloat
    let fraction: Double
    let resize: (CGFloat) -> Void
    let finish: () -> Void
    func makeNSView(context: Context) -> SplitHandleView { SplitHandleView() }
    func updateNSView(_ view: SplitHandleView, context: Context) {
        view.axis = axis
        view.primarySize = topHeight
        view.resize = resize
        view.finish = finish
        view.setAccessibilityLabel(axis == .vertical ? "上下区域分隔线" : "左右区域分隔线")
        view.setAccessibilityHelp(axis == .vertical
            ? "上下拖动调整上下区域的空间，也可用上下方向键调整。"
            : "左右拖动调整左右区域的宽度，也可用左右方向键调整。")
        view.setAccessibilityValue("\(axis == .vertical ? "上方" : "左侧") \(Int(fraction * 100))%")
    }
}

final class SplitHandleView: NSView, WritingCursorProviding {
    var axis: StudySplitAxis = .vertical
    var primarySize: CGFloat = 0
    var resize: ((CGFloat) -> Void)?
    var finish: (() -> Void)?
    private var cursorTracking: WritingCursorTracking!
    private var startCoordinate: CGFloat = 0
    private var startSize: CGFloat = 0
    private var dragging = false
    var writingCursorRole: WritingCursorRole { axis == .vertical ? .splitResize : .columnResize }
    private var resizeCursor: NSCursor { axis == .vertical ? .resizeUpDown : .resizeLeftRight }
    private func coordinate(_ event: NSEvent) -> CGFloat {
        axis == .vertical ? -event.locationInWindow.y : event.locationInWindow.x
    }
    override var acceptsFirstResponder: Bool { true }
    override init(frame: NSRect) {
        super.init(frame: frame)
        cursorTracking = WritingCursorTracking(view: self)
        setAccessibilityElement(true)
        setAccessibilityRole(.splitter)
        setAccessibilityLabel("上下区域分隔线")
        setAccessibilityHelp("上下拖动调整上下区域的空间，也可用上下方向键调整。")
    }
    required init?(coder: NSCoder) { nil }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        startCoordinate = coordinate(event)
        startSize = primarySize
        dragging = true
        resizeCursor.push()
    }
    override func mouseDragged(with event: NSEvent) {
        guard dragging else { return }
        // Window coordinates stay fixed even while this handle changes position.
        resize?(startSize + coordinate(event) - startCoordinate)
    }
    override func mouseUp(with event: NSEvent) {
        guard dragging else { return }
        resize?(startSize + coordinate(event) - startCoordinate)
        dragging = false
        finish?()
        NSCursor.pop()
        if let window { WritingCursors.update(in: window, at: window.mouseLocationOutsideOfEventStream) }
    }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == (axis == .vertical ? 126 : 123) {
            resize?(primarySize - 18); finish?()
        } else if event.keyCode == (axis == .vertical ? 125 : 124) {
            resize?(primarySize + 18); finish?()
        } else {
            super.keyDown(with: event)
        }
    }
    override func accessibilityPerformIncrement() -> Bool {
        resize?(primarySize + 18); finish?(); return true
    }
    override func accessibilityPerformDecrement() -> Bool {
        resize?(primarySize - 18); finish?(); return true
    }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        if axis == .vertical {
            let y = bounds.midY
            path.move(to: NSPoint(x: 2, y: y))
            path.curve(to: NSPoint(x: max(2, bounds.width - 2), y: y),
                       controlPoint1: NSPoint(x: bounds.width * 0.33, y: y - 1),
                       controlPoint2: NSPoint(x: bounds.width * 0.68, y: y + 1))
        } else {
            let x = bounds.midX
            path.move(to: NSPoint(x: x, y: 2))
            path.curve(to: NSPoint(x: x, y: max(2, bounds.height - 2)),
                       controlPoint1: NSPoint(x: x - 1, y: bounds.height * 0.33),
                       controlPoint2: NSPoint(x: x + 1, y: bounds.height * 0.68))
        }
        path.lineWidth = 1.6; path.lineCapStyle = .round
        NSColor.labelColor.withAlphaComponent(0.26).setStroke(); path.stroke()
    }
}
