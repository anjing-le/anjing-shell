import AppKit
import SwiftUI

@main
struct ShellXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        Settings { EmptyView() }.commands {
            CommandGroup(replacing: .newItem) {
                Button("新建模拟标签") { delegate.newTab() }.keyboardShortcut("t")
                Button("显示 ShellX") { delegate.showWindow() }
            }
            CommandGroup(replacing: .appSettings) {
                Button("设置…") { delegate.model.settings.toggle(); delegate.showWindow() }.keyboardShortcut(",")
            }
            CommandGroup(after: .windowArrangement) {
                Button("关闭标签或窗口") { delegate.closeTab() }.keyboardShortcut("w")
                Button("最小化") { delegate.window?.performMiniaturize(nil) }.keyboardShortcut("m")
                Button("切换全屏") { delegate.window?.toggleFullScreen(nil) }.keyboardShortcut("f", modifiers: [.control, .command])
            }
            CommandMenu("工作区") {
                Button("左右分屏") { delegate.model.active?.split(vertical: false) }.keyboardShortcut("d")
                Button("上下分屏") { delegate.model.active?.split(vertical: true) }.keyboardShortcut("d", modifiers: [.command, .shift])
                Button("服务器侧栏") { delegate.toggle("sidebar.visible") }.keyboardShortcut("b")
                Button("文件栏") { delegate.toggle("files.visible") }.keyboardShortcut("e", modifiers: [.command, .shift])
                Button("上一个标签") { delegate.model.cycle(-1) }.keyboardShortcut("[", modifiers: [.command, .shift])
                Button("下一个标签") { delegate.model.cycle(1) }.keyboardShortcut("]", modifiers: [.command, .shift])
            }
        }
    }
}
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: PaperWindow?
    let model = Workspace()
    private var monitor: Any?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        UserDefaults.standard.register(defaults: ["sidebar.visible": true, "files.visible": true])
        let rect = NSRect(x: 0, y: 0, width: 1320, height: 820)
        let window = PaperWindow(contentRect: rect)
        window.contentMinSize = NSSize(width: 980, height: 560)
        // ShellX uses a readable light paper workspace regardless of system theme.
        window.appearance = NSAppearance(named: .aqua)
        window.setFrameAutosaveName("ShellXWorkspace")
        let paper = PaperView(frame: rect)
        let host = NSHostingView(rootView: WorkspaceView(model: model))
        host.frame = paper.bounds; host.autoresizingMask = [.width, .height]
        paper.addSubview(host, positioned: .below, relativeTo: paper.subviews.first)
        window.contentView = paper
        window.center(); self.window = window
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            if event.keyCode == 53, self.model.sidebarPanel != nil {
                if let text = self.window?.firstResponder as? NSTextView, text.hasMarkedText() { return event }
                self.model.sidebarPanel = nil; return nil
            }
            if event.keyCode == 53 && self.model.settings {
                if let text = self.window?.firstResponder as? NSTextView, text.hasMarkedText() { return event }
                self.model.settings = false; return nil
            }
            return event
        }
        showWindow()
    }
    func newTab() { model.open(model.active?.server ?? Server.examples[0]); showWindow() }
    func closeTab() {
        if model.settings { model.settings = false }
        else if let id = model.selected { model.close(id) }
        else { window?.performClose(nil) }
    }
    func toggle(_ key: String) { UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: key), forKey: key) }
    func showWindow() {
        if window?.isMiniaturized == true { window?.deminiaturize(nil) }
        window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWindow(); return false }
}
