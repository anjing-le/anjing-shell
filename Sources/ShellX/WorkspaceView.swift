import AppKit
import SwiftUI
import UniformTypeIdentifiers

// Native hit targets let the same cursorUpdate owner resolve every button.
struct ActionTarget: NSViewRepresentable {
    let label: String
    var enabled = true
    let action: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> HitButton {
        let button = HitButton()
        button.isBordered = false; button.title = ""; button.bezelStyle = .regularSquare
        button.setButtonType(.momentaryChange)
        button.target = context.coordinator; button.action = #selector(Coordinator.activate)
        return button
    }
    func updateNSView(_ button: HitButton, context: Context) {
        context.coordinator.action = action; button.isEnabled = enabled
        button.setAccessibilityLabel(label); button.toolTip = label
    }
    final class Coordinator: NSObject {
        var action: (() -> Void)?
        @objc func activate() { action?() }
    }
}
final class HitButton: NSButton {
    private var tracking: WritingCursorTracking!
    override init(frame: NSRect) { super.init(frame: frame); tracking = WritingCursorTracking(view: self) }
    required init?(coder: NSCoder) { nil }
    override func draw(_ dirtyRect: NSRect) {
        if window?.firstResponder === self {
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6)
            NSColor.keyboardFocusIndicatorColor.withAlphaComponent(0.6).setStroke(); path.lineWidth = 2; path.stroke()
        }
    }
}
struct PaperAction<Content: View>: View {
    let label: String
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var hovered = false
    var body: some View {
        content().allowsHitTesting(false)
            .background(hovered ? Ink.main.opacity(0.055) : .clear, in: RoundedRectangle(cornerRadius: 8))
            .overlay(ActionTarget(label: label, action: action))
            .onHover { hovered = $0 }
    }
}
struct IconAction: View {
    let icon: String
    let label: String
    var selected = false
    let action: () -> Void
    var body: some View {
        PaperAction(label: label, action: action) {
            Image(systemName: icon).font(.system(size: 14, weight: .regular))
                .foregroundStyle(selected ? Ink.sage : Ink.muted)
                .frame(width: 30, height: 30)
                .background(selected ? Ink.pale.opacity(0.75) : .clear, in: RoundedRectangle(cornerRadius: 7))
        }
    }
}
struct WorkspaceView: View {
    @ObservedObject var model: Workspace
    @AppStorage("sidebar.visible") private var sidebar = true
    @AppStorage("files.visible") private var files = true
    @AppStorage("sidebar.width") private var sidebarWidth = 206.0
    @AppStorage("files.width") private var fileWidth = 252.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(spacing: 0) {
            topBar
            if model.settings { settings }
            else {
                GeometryReader { geometry in
                    let side = min(sidebarWidth, max(170, geometry.size.width * 0.24))
                    let right = min(fileWidth, max(200, geometry.size.width * 0.28))
                    ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        if sidebar {
                            serverSidebar.frame(width: side)
                            divider(size: side, fraction: 0.5) { sidebarWidth = min(280, max(170, $0)) }
                        }
                        center.frame(minWidth: 280, maxWidth: .infinity)
                        if files && model.active != nil {
                            divider(size: geometry.size.width - right, fraction: 0.5) { fileWidth = min(340, max(200, geometry.size.width - $0)) }
                            fileSidebar.frame(width: right)
                        }
                    }
                    if let panel = model.sidebarPanel {
                        Color.black.opacity(0.035).contentShape(Rectangle())
                            .onTapGesture { model.sidebarPanel = nil }
                            .accessibilityLabel("关闭侧栏面板")
                        SidebarPanelView(model: model, panel: panel)
                            .id(String(describing: panel))
                            .padding(.leading, sidebar ? side + 21 : 24)
                            .padding(.top, 10)
                    }
                    }
                }
            }
            bottomBar
        }
        .padding(.top, 28)
        .foregroundStyle(Ink.main)
        .font(.system(size: 12))
        .preferredColorScheme(.light)
        .overlay(alignment: .bottom) {
            if let notice = model.notice {
                Text(notice).font(.system(size: 12)).padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color(red: 0.96, green: 0.95, blue: 0.90), in: Capsule())
                    .overlay(Capsule().stroke(Ink.line)).padding(.bottom, 38).allowsHitTesting(false)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: model.settings)
    }
    private var topBar: some View {
        HStack(spacing: 9) {
            Text("ShellX").font(.system(size: 17, weight: .semibold, design: .rounded)).tracking(-0.6)
            Text("本地预览").font(.system(size: 10)).foregroundStyle(Ink.sage)
                .padding(.horizontal, 8).padding(.vertical, 4).background(Ink.pale.opacity(0.6), in: Capsule())
            Spacer()
            IconAction(icon: "sidebar.left", label: "显示或隐藏服务器栏", selected: sidebar) { model.sidebarPanel = nil; sidebar.toggle() }
            IconAction(icon: "rectangle.split.2x1", label: "左右分屏") { model.active?.split(vertical: false) }
            IconAction(icon: "rectangle.split.1x2", label: "上下分屏") { model.active?.split(vertical: true) }
            Color.clear.frame(width: 1, height: 14).overlay(Ink.line)
            IconAction(icon: "sidebar.right", label: "显示或隐藏文件栏", selected: files) { files.toggle() }
            IconAction(icon: "gearshape", label: "设置") { model.settings.toggle() }
        }.padding(.horizontal, 22).padding(.bottom, 12)
    }
    private var serverSidebar: some View {
        ServerSidebar(model: model)
    }
    private var center: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 5) {
                    ForEach(Array(model.sessions.enumerated()), id: \.element.id) { index, session in
                        SessionTab(session: session, index: index, selected: model.selected == session.id,
                                   select: { model.select(session.id) }, close: { model.close(session.id) })
                            .onDrag { NSItemProvider(object: session.id.uuidString as NSString) }
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                guard let provider = providers.first else { return false }
                                _ = provider.loadObject(ofClass: String.self) { value, _ in
                                    guard let value, let id = UUID(uuidString: value) else { return }
                                    Task { @MainActor in
                                        guard let from = model.sessions.firstIndex(where: { $0.id == id }), let to = model.sessions.firstIndex(where: { $0.id == session.id }) else { return }
                                        let item = model.sessions.remove(at: from); model.sessions.insert(item, at: min(to, model.sessions.count))
                                    }
                                }; return true
                            }
                    }
                    IconAction(icon: "plus", label: "新建模拟会话") { model.open(model.active?.server ?? Server.examples[0]) }
                }.padding(.horizontal, 7).padding(.vertical, 7)
            }.scrollIndicators(.hidden).frame(height: 48)
            if let session = model.active {
                SessionView(session: session).id(session.id)
                    .padding(.horizontal, 8).padding(.bottom, 12)
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "terminal").font(.system(size: 34, weight: .ultraLight)).foregroundStyle(Ink.sage)
                    Text("从左侧打开一台服务器").font(.system(size: 14)).foregroundStyle(Ink.muted)
                    PaperAction(label: "打开模拟服务器", action: { model.open(Server.examples[0]) }) {
                        Text("打开 garden-api").padding(.horizontal, 15).padding(.vertical, 10).background(Ink.pale, in: Capsule())
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    private var fileSidebar: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("文件").font(.system(size: 13, weight: .medium))
                Spacer()
                IconAction(icon: "arrow.up", label: "上级目录") { model.filePath = "/srv/garden"; model.selectedFile = nil }
                IconAction(icon: "arrow.up.doc", label: "模拟上传") { model.mockTransfer("example.txt", upload: true) }
            }
            HStack(spacing: 6) {
                Image(systemName: "folder").foregroundStyle(Ink.sage)
                Text(model.filePath).font(.system(size: 10, design: .monospaced)).lineLimit(1).truncationMode(.middle)
            }.foregroundStyle(Ink.muted).padding(.bottom, 5)
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(model.files) { file in
                        PaperAction(label: "\(file.folder ? "打开目录" : "选择文件") \(file.name)", action: { model.choose(file) }) {
                            HStack(spacing: 9) {
                                Image(systemName: file.folder ? "folder.fill" : "doc.text").font(.system(size: 14))
                                    .foregroundStyle(file.folder ? Ink.blue.opacity(0.7) : Ink.muted)
                                Text(file.name).font(.system(size: 11)).lineLimit(1).truncationMode(.middle)
                                Spacer(minLength: 2)
                                Text(file.size).font(.system(size: 9)).foregroundStyle(Ink.muted)
                            }.padding(.horizontal, 9).padding(.vertical, 10)
                                .background(model.selectedFile == file.id ? Ink.pale.opacity(0.6) : .clear, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }.scrollIndicators(.hidden)
            if let file = model.selectedFile {
                PaperAction(label: "模拟下载 \(file)", action: { model.mockTransfer(file, upload: false) }) {
                    HStack { Image(systemName: "arrow.down.to.line"); Text("模拟下载") }.font(.system(size: 11))
                        .frame(maxWidth: .infinity).padding(.vertical, 9).background(Ink.pale.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            FileDropZone { name in model.mockTransfer(name, upload: true) }
        }.padding(.leading, 7).padding(.trailing, 18).padding(.top, 12).padding(.bottom, 18)
    }
    private var bottomBar: some View {
        HStack(spacing: 7) {
            Circle().fill(Ink.sage.opacity(0.7)).frame(width: 5, height: 5)
            Text(model.active.map { "\($0.server.name) · 模拟会话" } ?? "没有打开的会话")
            Spacer()
            if let transfer = model.transfer {
                Text(transfer).lineLimit(1)
                IconAction(icon: "xmark", label: "关闭传输状态") { model.transfer = nil }.frame(width: 20, height: 20)
            } else { Text("⌘T 新标签     ⌘D 分屏     ⌘⇧[ / ] 切换") }
        }.font(.system(size: 10)).foregroundStyle(Ink.muted).padding(.horizontal, 24).frame(height: 31)
    }
    private var settings: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack { Text("设置").font(.system(size: 23, weight: .medium)); Spacer(); IconAction(icon: "xmark", label: "返回工作区") { model.settings = false } }
            Text("外观与工作区").font(.system(size: 11)).foregroundStyle(Ink.muted)
            HStack { Text("服务器侧栏"); Spacer(); PaperAction(label: "切换服务器侧栏", action: { sidebar.toggle() }) { Text(sidebar ? "显示" : "隐藏").foregroundStyle(Ink.sage).padding(8) } }
            HStack { Text("文件栏"); Spacer(); PaperAction(label: "切换文件栏", action: { files.toggle() }) { Text(files ? "显示" : "隐藏").foregroundStyle(Ink.sage).padding(8) } }
            Rectangle().fill(Ink.line).frame(height: 1)
            Text("本地 mock · 所有服务器、日志与文件均为示例。")
                .font(.system(size: 12)).foregroundStyle(Ink.muted)
            Text("⌘, 设置    Esc 返回    ⌘B 侧栏    ⌘⇧E 文件栏")
                .font(.system(size: 11)).foregroundStyle(Ink.muted)
            Spacer()
        }.padding(42).frame(maxWidth: 640, maxHeight: .infinity).frame(maxWidth: .infinity)
    }
    private func divider(size: CGFloat, fraction: Double, resize: @escaping (CGFloat) -> Void) -> some View {
        StudySplitHandle(axis: .horizontal, topHeight: size, fraction: fraction, resize: resize, finish: {})
            .frame(width: 16).padding(.vertical, 17)
    }
}

struct SessionTab: View {
    @ObservedObject var session: Session
    let index: Int
    let selected: Bool
    let select: () -> Void
    let close: () -> Void
    @State private var hovered = false
    var body: some View {
        HStack(spacing: 0) {
            PaperAction(label: "切换到 \(session.server.name) 标签 \(index + 1)", action: select) {
                HStack(spacing: 7) {
                    Circle().fill(session.server.tint).frame(width: 5, height: 5)
                    Text(session.server.name).font(.system(size: 11, weight: selected ? .medium : .regular))
                    if session.second != nil { Image(systemName: "rectangle.split.2x1").font(.system(size: 9)).foregroundStyle(Ink.muted) }
                }.padding(.leading, 11).padding(.trailing, 7).frame(height: 33)
            }
            IconAction(icon: "xmark", label: "关闭 \(session.server.name) 标签") { close() }
                .frame(width: 25, height: 27).opacity(selected || hovered ? 1 : 0)
                .allowsHitTesting(selected || hovered).accessibilityHidden(!(selected || hovered))
        }.padding(.trailing, 3).background(selected ? Color.white.opacity(0.65) : .clear, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? Ink.line : .clear))
            .onHover { hovered = $0 }
    }
}

struct SessionView: View {
    @ObservedObject var session: Session
    var body: some View {
        GeometryReader { geometry in
            if let second = session.second {
                let available = max(1, (session.vertical ? geometry.size.height : geometry.size.width) - 18)
                let minimum = min(session.vertical ? 140.0 : 170.0, available * 0.4)
                let size = min(available - minimum, max(minimum, available * session.splitFraction))
                let resize: (CGFloat) -> Void = { value in session.splitFraction = min(available - minimum, max(minimum, value)) / available }
                let finish: () -> Void = { UserDefaults.standard.set(session.splitFraction, forKey: "terminal.fraction") }
                if session.vertical {
                    VStack(spacing: 0) {
                        pane(session.main).frame(height: size)
                        StudySplitHandle(topHeight: size, fraction: session.splitFraction, resize: resize, finish: finish).frame(height: 18).padding(.horizontal, 14)
                        pane(second)
                    }
                } else {
                    HStack(spacing: 0) {
                        pane(session.main).frame(width: size)
                        StudySplitHandle(axis: .horizontal, topHeight: size, fraction: session.splitFraction, resize: resize, finish: finish).frame(width: 18).padding(.vertical, 14)
                        pane(second)
                    }
                }
            } else { pane(session.main) }
        }
    }
    private func pane(_ terminal: MockTerminal) -> some View {
        TerminalPane(terminal: terminal, focused: session.focusedPane == terminal.id,
                     focus: { session.focusedPane = terminal.id },
                     close: session.second != nil ? {
                         // Closing either pane preserves the other pane's transcript.
                         if terminal.id == session.main.id, let second = session.second {
                             session.main.lines = second.lines; session.main.input = second.input
                             session.main.path = second.path; session.main.history = second.history
                         }
                         session.second = nil; session.focusedPane = session.main.id
                     } : nil)
    }
}
struct TerminalPane: View {
    @ObservedObject var terminal: MockTerminal
    let focused: Bool
    let focus: () -> Void
    let close: (() -> Void)?
    @State private var search = ""
    @State private var searching = false
    @State private var fontSize: CGFloat = 11
    @FocusState private var inputFocused: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(terminal.server.user).foregroundStyle(Ink.sage)
                Text("@ \(terminal.server.name)").foregroundStyle(Ink.muted).lineLimit(1)
                Spacer(minLength: 0)
                IconAction(icon: "magnifyingglass", label: "搜索此终端输出", selected: searching) { searching.toggle() }
                if let close { IconAction(icon: "xmark", label: "关闭此分屏", action: close) }
            }.font(.system(size: 10, design: .monospaced)).padding(.leading, 13).padding(.trailing, 5).frame(height: 39)
            if searching {
                HStack {
                    TextField("搜索当前输出", text: $search).textFieldStyle(.plain)
                    Text("\(terminal.lines.filter { !search.isEmpty && $0.text.localizedCaseInsensitiveContains(search) }.count)").foregroundStyle(Ink.muted)
                }.font(.system(size: 11)).padding(9).background(Ink.pale.opacity(0.3)).padding(.horizontal, 10).padding(.bottom, 5)
            }
            TerminalOutput(lines: terminal.lines, search: search, fontSize: fontSize)
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("➜").foregroundStyle(Ink.sage)
                TextField("输入模拟命令", text: $terminal.input).textFieldStyle(.plain)
                    .focused($inputFocused).onSubmit { focus(); terminal.submit() }
                    .onKeyPress(.upArrow) {
                        guard !terminal.history.isEmpty else { return .ignored }
                        terminal.historyIndex = max(0, terminal.historyIndex - 1)
                        terminal.input = terminal.history[terminal.historyIndex]; return .handled
                    }
                    .onKeyPress(.downArrow) {
                        terminal.historyIndex = min(terminal.history.count, terminal.historyIndex + 1)
                        terminal.input = terminal.historyIndex < terminal.history.count ? terminal.history[terminal.historyIndex] : ""; return .handled
                    }
            }.font(.system(size: 12, design: .monospaced)).padding(.horizontal, 14).padding(.vertical, 14)
                .background(Ink.pale.opacity(focused ? 0.15 : 0.05))
        }.background(Color.white.opacity(0.47), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(focused ? Ink.sage.opacity(0.40) : Ink.line, lineWidth: 1))
            .onChange(of: inputFocused) { _, value in if value { focus() } }
    }
}
struct FileDropZone: View {
    let drop: (String) -> Void
    @State private var targeted = false
    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: "arrow.up.doc").font(.system(size: 19, weight: .ultraLight))
            Text("拖入文件").font(.system(size: 11))
            Text("只预览传输状态").font(.system(size: 9)).foregroundStyle(Ink.muted)
        }.foregroundStyle(Ink.sage).frame(maxWidth: .infinity).padding(.vertical, 23)
            .background(Ink.pale.opacity(targeted ? 0.6 : 0.18), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Ink.sage.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 5])))
            .onDrop(of: [.fileURL], isTargeted: $targeted) { providers in
                guard let provider = providers.first else { return false }
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { value, _ in
                    guard let data = value as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    let name = url.lastPathComponent
                    Task { @MainActor in drop(name) }
                }; return true
            }
    }
}
