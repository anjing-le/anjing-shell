import AppKit
import SwiftUI

enum Ink {
    static let main = Color(red: 0.24, green: 0.26, blue: 0.24)
    static let muted = Color(red: 0.52, green: 0.53, blue: 0.49)
    static let sage = Color(red: 0.37, green: 0.49, blue: 0.39)
    static let pale = Color(red: 0.88, green: 0.91, blue: 0.85)
    static let blue = Color(red: 0.39, green: 0.53, blue: 0.64)
    static let peach = Color(red: 0.74, green: 0.48, blue: 0.35)
    static let line = Color(red: 0.42, green: 0.43, blue: 0.36).opacity(0.17)
}

struct Server: Identifiable, Equatable {
    let id: Int
    var name: String
    var host: String
    var group: String
    let note: String
    let tint: Color
    var port = 22
    var user = "deploy"
    static let examples: [Server] = [
        .init(id: 0, name: "garden-api", host: "192.0.2.10", group: "日常开发", note: "开发 · Ubuntu", tint: Ink.sage),
        .init(id: 1, name: "garden-worker", host: "192.0.2.11", group: "日常开发", note: "开发 · Ubuntu", tint: Ink.sage),
        .init(id: 2, name: "staging-web", host: "192.0.2.20", group: "测试环境", note: "测试 · Debian", tint: Ink.blue),
        .init(id: 3, name: "staging-db", host: "192.0.2.21", group: "测试环境", note: "测试 · Debian", tint: Ink.blue),
        .init(id: 4, name: "home-lab", host: "192.0.2.30", group: "我的空间", note: "个人 · Ubuntu", tint: Ink.peach)
    ]
}
struct TerminalLine: Identifiable {
    let id = UUID()
    let text: String
    var tone: Color = Ink.main
}
final class MockTerminal: ObservableObject, Identifiable {
    let id = UUID()
    let server: Server
    @Published var lines: [TerminalLine]
    @Published var input = ""
    @Published var path = "/srv/garden"
    @Published var history: [String] = []
    var historyIndex = 0
    init(server: Server, logs: Bool = false) {
        self.server = server
        lines = [
            .init(text: "ShellX · 本地模拟会话", tone: Ink.muted),
            .init(text: "\(server.user)@\(server.host):\(server.port)   /   \(server.name)", tone: Ink.muted),
            .init(text: ""),
            .init(text: "➜  /srv/garden  \(logs ? "tail -f logs/app.log" : "ls -lah")", tone: Ink.sage)
        ] + (logs ? Self.logs : Self.listing)
    }
    static var listing: [TerminalLine] { [
        .init(text: "total 32K", tone: Ink.muted),
        .init(text: "drwxr-xr-x   6 deploy  deploy  4.0K  Nov 04 09:12  ."),
        .init(text: "drwxr-xr-x   3 deploy  deploy  4.0K  Nov 01 10:30  .."),
        .init(text: "drwxr-xr-x   2 deploy  deploy  4.0K  Nov 04 09:10  config/", tone: Ink.blue),
        .init(text: "drwxr-xr-x   2 deploy  deploy  4.0K  Nov 04 09:12  logs/", tone: Ink.blue),
        .init(text: "drwxr-xr-x   3 deploy  deploy  4.0K  Nov 03 18:24  releases/", tone: Ink.blue),
        .init(text: "-rw-r--r--   1 deploy  deploy   812  Nov 04 09:10  compose.yml"),
        .init(text: "-rw-r--r--   1 deploy  deploy  1.2K  Nov 02 14:30  README.md"),
        .init(text: ""),
        .init(text: "试试 ls、pwd、date 或 tail -f logs/app.log", tone: Ink.muted)
    ] }
    static var logs: [TerminalLine] { [
        .init(text: "09:12:01.204  INFO   service starting", tone: Ink.muted),
        .init(text: "09:12:01.318  INFO   configuration loaded"),
        .init(text: "09:12:01.502  INFO   database pool ready"),
        .init(text: "09:12:01.610  INFO   listening on :8080", tone: Ink.sage),
        .init(text: ""),
        .init(text: "09:12:04.126  GET    /health           200    2ms"),
        .init(text: "09:12:06.472  GET    /api/notes        200   18ms"),
        .init(text: "09:12:08.031  POST   /api/notes        201   24ms"),
        .init(text: "09:12:09.215  WARN   slow query       248ms", tone: Ink.peach),
        .init(text: "09:12:10.901  GET    /api/gardens      200   12ms"),
        .init(text: "09:12:12.048  INFO   background job completed", tone: Ink.sage),
        .init(text: ""),
        .init(text: "以上为静态模拟日志", tone: Ink.muted)
    ] }
    func submit() {
        let command = input.trimmingCharacters(in: .whitespacesAndNewlines)
        input = ""
        guard !command.isEmpty else { return }
        history.append(command); historyIndex = history.count
        lines.append(.init(text: "➜  \(path)  \(command)", tone: Ink.sage))
        switch command {
        case "clear": lines = []
        case "ls", "ls -l", "ls -la", "ls -lah": lines += Self.listing
        case "pwd": lines.append(.init(text: path))
        case "date": lines.append(.init(text: "2026-11-04 09:12:00 CST · 模拟时间"))
        case "whoami": lines.append(.init(text: "deploy · 模拟用户"))
        case "help": lines.append(.init(text: "模拟命令：ls · pwd · date · whoami · tail -f logs/app.log · clear"))
        case "tail -f logs/app.log", "tail logs/app.log": lines += Self.logs
        default: lines.append(.init(text: "本地预览未执行此命令。输入 help 查看模拟命令。", tone: Ink.peach))
        }
        if lines.count > 500 { lines.removeFirst(lines.count - 500) }
    }
}
final class Session: ObservableObject, Identifiable {
    let id = UUID()
    let server: Server
    let main: MockTerminal
    @Published var second: MockTerminal?
    @Published var focusedPane: UUID
    @Published var vertical = false
    @Published var splitFraction: Double = UserDefaults.standard.object(forKey: "terminal.fraction") as? Double ?? 0.52
    init(server: Server, split: Bool = false) {
        self.server = server
        main = MockTerminal(server: server)
        focusedPane = main.id
        if split { second = MockTerminal(server: server, logs: true) }
    }
    func split(vertical: Bool) {
        self.vertical = vertical
        if second == nil { second = MockTerminal(server: server, logs: true) }
    }
}
struct RemoteFile: Identifiable {
    let name: String
    let size: String
    let folder: Bool
    var id: String { name }
}
@MainActor
final class Workspace: ObservableObject {
    @Published var servers = Server.examples
    @Published var groups = ["日常开发", "测试环境", "我的空间"]
    @Published var sidebarPanel: SidebarPanel?
    @Published var sessions = [Session(server: Server.examples[0], split: true), Session(server: Server.examples[2])]
    @Published var selected: UUID?
    @Published var query = ""
    @Published var collapsed: Set<String> = []
    @Published var settings = false
    @Published var notice: String?
    @Published var transfer: String?
    @Published var filePath = "/srv/garden"
    @Published var selectedFile: String?
    var noticeTask: Task<Void, Never>?
    init() { selected = sessions.first?.id }
    var active: Session? { sessions.first { $0.id == selected } }
    var searchTerms: [String] { query.split(whereSeparator: { $0.isWhitespace }).map(String.init) }
    var searching: Bool { !searchTerms.isEmpty }
    var matchingServers: [Server] {
        servers.filter { server in
            let content = "\(server.name) \(server.host) \(server.group) \(server.user)"
            return searchTerms.allSatisfy { content.localizedCaseInsensitiveContains($0) }
        }
    }
    func activate(_ server: Server) {
        if let existing = sessions.last(where: { $0.server.id == server.id }) { select(existing.id) }
        else { open(server) }
    }
    func saveServer(id: Int?, name: String, host: String, group: String, user: String, port: String) -> String? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = user.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "给服务器取个名字。" }
        guard !host.isEmpty, !host.contains(where: { $0.isWhitespace }), !host.contains("://"), !host.contains("/"), !host.contains("@") else { return "填写 IP 或主机名，不包含协议、路径或用户名。" }
        guard let portNumber = Int(port), (1...65535).contains(portNumber) else { return "端口应为 1–65535。" }
        guard !user.isEmpty, !user.contains(where: { $0.isWhitespace }) else { return "填写不含空格的用户名。" }
        guard groups.contains(group) else { return "选一个分组。" }
        let existing = id.flatMap { id in servers.first { $0.id == id } }
        var server = Server(id: id ?? ((servers.map(\.id).max() ?? -1) + 1), name: name, host: host, group: group, note: "模拟服务器", tint: existing?.tint ?? Ink.sage)
        server.port = portNumber; server.user = user
        if let index = servers.firstIndex(where: { $0.id == server.id }) { servers[index] = server }
        else { servers.append(server) }
        collapsed.remove(group); query = ""; sidebarPanel = nil
        return nil
    }
    func saveGroup(original: String?, name: String) -> String? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "填写分组名称。" }
        guard !groups.contains(where: { $0 != original && $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) else { return "已经有这个分组了。" }
        if let original, let index = groups.firstIndex(of: original) {
            groups[index] = name
            for i in servers.indices where servers[i].group == original { servers[i].group = name }
            if collapsed.remove(original) != nil { collapsed.insert(name) }
        } else { groups.append(name) }
        query = ""; sidebarPanel = nil
        return nil
    }
    func open(_ server: Server) {
        let session = Session(server: server); sessions.append(session); selected = session.id
        filePath = "/srv/garden"; selectedFile = nil
    }
    func select(_ id: UUID) { selected = id; filePath = "/srv/garden"; selectedFile = nil }
    func close(_ id: UUID) {
        guard let i = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions.remove(at: i)
        if selected == id { selected = sessions.isEmpty ? nil : sessions[min(i, sessions.count - 1)].id }
    }
    func cycle(_ direction: Int) {
        guard !sessions.isEmpty else { return }
        let i = sessions.firstIndex(where: { $0.id == selected }) ?? 0
        select(sessions[(i + direction + sessions.count) % sessions.count].id)
    }
    func message(_ text: String) {
        noticeTask?.cancel(); notice = text
        noticeTask = Task { try? await Task.sleep(for: .seconds(3)); if !Task.isCancelled { notice = nil } }
    }
    var files: [RemoteFile] {
        switch filePath {
        case "/srv/garden/logs": return [.init(name: "app.log", size: "24.8 KB", folder: false), .init(name: "access.log", size: "8.2 KB", folder: false)]
        case "/srv/garden/config": return [.init(name: "application.yml", size: "1.8 KB", folder: false)]
        case "/srv/garden/releases": return [.init(name: "garden-v0.8.2.tar.gz", size: "12.4 MB", folder: false)]
        default: return [.init(name: "config", size: "", folder: true), .init(name: "logs", size: "", folder: true), .init(name: "releases", size: "", folder: true), .init(name: "compose.yml", size: "812 B", folder: false), .init(name: "README.md", size: "1.2 KB", folder: false)]
        }
    }
    func choose(_ file: RemoteFile) {
        selectedFile = file.id
        if file.folder { filePath += "/" + file.name; selectedFile = nil }
    }
    func mockTransfer(_ name: String, upload: Bool) { transfer = "\(upload ? "上传" : "下载") · \(name) · 模拟完成，未读写文件" }
}

enum SidebarPanel: Equatable {
    case add
    case server(id: Int?, group: String)
    case group(original: String?)
    case serverActions(Int)
    case groupActions(String)
}
