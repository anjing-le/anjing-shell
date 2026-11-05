import AppKit
import SwiftUI

struct TerminalOutput: NSViewRepresentable {
    let lines: [TerminalLine]
    let search: String
    let fontSize: CGFloat
    func makeNSView(context: Context) -> OutputScroll { OutputScroll() }
    func updateNSView(_ view: OutputScroll, context: Context) { view.update(lines: lines, search: search, size: fontSize) }
}

final class OutputScroll: NSScrollView {
    private let output = NSTextView()
    private var signature = ""
    private var lastCount = 0
    private var natural = NSSize.zero
    private var tracking: WritingCursorTracking!
    override init(frame: NSRect) {
        super.init(frame: frame)
        drawsBackground = false; borderType = .noBorder
        hasVerticalScroller = false; hasHorizontalScroller = false
        horizontalScrollElasticity = .automatic; verticalScrollElasticity = .automatic
        output.isEditable = false; output.isSelectable = true; output.isRichText = false
        output.drawsBackground = false; output.textContainerInset = NSSize(width: 14, height: 12)
        output.isHorizontallyResizable = false; output.isVerticallyResizable = false
        output.autoresizingMask = []
        output.textContainer?.widthTracksTextView = false
        output.textContainer?.containerSize = NSSize(width: 100_000, height: 100_000_000)
        output.textContainer?.lineFragmentPadding = 0
        output.setAccessibilityLabel("模拟终端输出")
        documentView = output
        tracking = WritingCursorTracking(view: output)
    }
    required init?(coder: NSCoder) { nil }
    func update(lines: [TerminalLine], search: String, size: CGFloat) {
        let key = lines.map { $0.id.uuidString }.joined() + search + String(Double(size))
        guard signature != key else { return }; signature = key
        let oldOrigin = contentView.bounds.origin
        let font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 7
        let text = NSMutableAttributedString(string: "")
        var width: CGFloat = 0
        for (index, line) in lines.enumerated() {
            let part = NSMutableAttributedString(string: line.text + (index == lines.count - 1 ? "" : "\n"), attributes: [
                .font: font, .foregroundColor: NSColor(line.tone), .paragraphStyle: paragraph
            ])
            if !search.isEmpty {
                let source = part.string as NSString
                var range = NSRange(location: 0, length: source.length)
                while range.length > 0 {
                    let found = source.range(of: search, options: [.caseInsensitive], range: range)
                    if found.location == NSNotFound { break }
                    part.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.25), range: found)
                    range = NSRange(location: NSMaxRange(found), length: source.length - NSMaxRange(found))
                }
            }
            width = max(width, (line.text as NSString).size(withAttributes: [.font: font]).width)
            text.append(part)
        }
        let selected = output.selectedRanges
        output.textStorage?.setAttributedString(text)
        output.selectedRanges = selected.filter { NSMaxRange($0.rangeValue) <= text.length }
        natural = NSSize(width: ceil(width) + 34, height: CGFloat(max(1, lines.count)) * (ceil(font.ascender - font.descender + font.leading) + 7) + 30)
        fitDocument()
        if lines.count != lastCount && lastCount != 0 {
            output.scrollRangeToVisible(NSRange(location: text.length, length: 0))
        } else { contentView.scroll(to: oldOrigin); reflectScrolledClipView(contentView) }
        lastCount = lines.count
    }
    override func layout() { super.layout(); fitDocument() }
    private func fitDocument() {
        let size = NSSize(width: max(contentSize.width, natural.width), height: max(contentSize.height, natural.height))
        if output.frame.size != size { output.setFrameSize(size) }
    }
}
