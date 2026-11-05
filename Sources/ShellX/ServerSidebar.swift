import SwiftUI

struct ServerSidebar: View {
    @ObservedObject var model: Workspace
    @FocusState private var searchFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 5) {
                Text("服务器").font(.system(size: 13, weight: .medium))
                Text("\(model.searching ? model.matchingServers.count : model.servers.count)")
                    .font(.system(size: 10)).foregroundStyle(Ink.muted)
                Spacer()
                IconAction(icon: "plus", label: "新增服务器或分组", selected: model.sidebarPanel == .add) {
                    model.sidebarPanel = model.sidebarPanel == .add ? nil : .add
                }
            }
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").foregroundStyle(Ink.muted)
                TextField("搜索名称、地址…", text: $model.query)
                    .textFieldStyle(.plain).font(.system(size: 11)).focused($searchFocused)
                    .onSubmit { if let first = model.matchingServers.first { model.activate(first) } }
                    .onKeyPress(.escape) { model.query = ""; return .handled }
                IconAction(icon: "xmark", label: "清空搜索") { model.query = ""; searchFocused = true }
                    .frame(width: 17, height: 20).opacity(model.query.isEmpty ? 0 : 1)
                    .allowsHitTesting(!model.query.isEmpty).accessibilityHidden(model.query.isEmpty)
            }.padding(.horizontal, 9).padding(.vertical, 7)
                .background(.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(searchFocused ? Ink.sage.opacity(0.5) : Ink.line.opacity(0.6)))
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    ForEach(model.groups, id: \.self) { group in
                        let matches = model.matchingServers.filter { $0.group == group }
                        if !model.searching || !matches.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                groupHeader(group, count: matches.count)
                                if model.searching || !model.collapsed.contains(group) {
                                    ForEach(matches) { server in serverRow(server) }
                                    if matches.isEmpty && !model.searching {
                                        PaperAction(label: "向\(group)添加服务器", action: { model.sidebarPanel = .server(id: nil, group: group) }) {
                                            Text("添加第一台服务器").font(.system(size: 10)).foregroundStyle(Ink.muted)
                                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10).padding(.vertical, 11)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if model.searching && model.matchingServers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("没有找到服务器").foregroundStyle(Ink.muted).font(.system(size: 12))
                            PaperAction(label: "从搜索结果新增服务器", action: { model.sidebarPanel = .server(id: nil, group: model.groups.first ?? "日常开发") }) {
                                Label("新增服务器", systemImage: "plus").font(.system(size: 11)).foregroundStyle(Ink.sage).padding(.vertical, 6)
                            }
                        }.padding(.horizontal, 9).padding(.top, 10)
                    }
                }
            }.scrollIndicators(.hidden)
            HStack(spacing: 6) {
                Image(systemName: "lock.shield").font(.system(size: 11))
                Text("仅模拟 · 未连接服务器").font(.system(size: 10))
            }.foregroundStyle(Ink.muted).padding(.leading, 8)
        }.padding(.leading, 18).padding(.trailing, 9).padding(.top, 8).padding(.bottom, 18)
    }
    private func groupHeader(_ group: String, count: Int) -> some View {
        HStack(spacing: 1) {
            PaperAction(label: "展开或收起\(group)", action: {
                guard !model.searching else { return }
                if model.collapsed.contains(group) { model.collapsed.remove(group) } else { model.collapsed.insert(group) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: !model.searching && model.collapsed.contains(group) ? "chevron.right" : "chevron.down")
                        .font(.system(size: 7, weight: .semibold))
                    Text(group).font(.system(size: 10, weight: .medium)).lineLimit(1)
                    Text("\(count)").font(.system(size: 9)).opacity(0.7)
                    Spacer(minLength: 0)
                }.foregroundStyle(Ink.muted).padding(.leading, 7).frame(height: 26)
            }
            IconAction(icon: "plus", label: "向\(group)新增服务器") { model.sidebarPanel = .server(id: nil, group: group) }.scaleEffect(0.75).frame(width: 19, height: 25)
            IconAction(icon: "ellipsis", label: "管理分组\(group)") { model.sidebarPanel = .groupActions(group) }.scaleEffect(0.75).frame(width: 19, height: 25)
        }
    }
    private func serverRow(_ server: Server) -> some View {
        let active = model.active?.server.id == server.id
        return HStack(spacing: 0) {
            PaperAction(label: "打开 \(server.name) 模拟会话", action: { model.activate(server) }) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "server.rack").font(.system(size: 14, weight: .light)).foregroundStyle(server.tint).padding(.top, 1)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(server.name).font(.system(size: 12, weight: active ? .medium : .regular)).lineLimit(1)
                        Text(server.host).font(.system(size: 10, design: .monospaced)).foregroundStyle(Ink.muted).lineLimit(1).truncationMode(.middle)
                    }
                    Spacer(minLength: 0)
                }.padding(.leading, 10).padding(.vertical, 11)
            }
            IconAction(icon: "ellipsis", label: "管理服务器\(server.name)") { model.sidebarPanel = .serverActions(server.id) }
                .scaleEffect(0.8).frame(width: 24).padding(.trailing, 3)
        }.background(active ? Ink.pale.opacity(0.7) : .clear, in: RoundedRectangle(cornerRadius: 9))
    }
}

struct SidebarPanelView: View {
    @ObservedObject var model: Workspace
    let panel: SidebarPanel
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                Text(title).font(.system(size: 15, weight: .medium))
                Spacer()
                IconAction(icon: "xmark", label: "关闭侧栏面板") { model.sidebarPanel = nil }
            }
            switch panel {
            case .add:
                menuItem("新增服务器", icon: "server.rack", shortcut: nil) { model.sidebarPanel = .server(id: nil, group: model.groups.first ?? "日常开发") }
                menuItem("新建分组", icon: "folder.badge.plus", shortcut: nil) { model.sidebarPanel = .group(original: nil) }
            case let .server(id, group):
                ServerEditor(model: model, id: id, group: group)
            case let .group(original):
                GroupEditor(model: model, original: original)
            case let .serverActions(id):
                if let server = model.servers.first(where: { $0.id == id }) {
                    menuItem("打开会话", icon: "terminal", shortcut: nil) { model.activate(server); model.sidebarPanel = nil }
                    menuItem("在新标签打开", icon: "plus.rectangle.on.rectangle", shortcut: nil) { model.open(server); model.sidebarPanel = nil }
                    menuItem("编辑与移动分组", icon: "slider.horizontal.3", shortcut: nil) { model.sidebarPanel = .server(id: id, group: server.group) }
                }
            case let .groupActions(group):
                menuItem("新增服务器", icon: "plus", shortcut: nil) { model.sidebarPanel = .server(id: nil, group: group) }
                menuItem("重命名分组", icon: "pencil", shortcut: nil) { model.sidebarPanel = .group(original: group) }
            }
        }.padding(19).frame(width: 340)
            .background(Color(red: 0.985, green: 0.98, blue: 0.955), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Ink.line))
            .shadow(color: Ink.main.opacity(0.11), radius: 20, x: 3, y: 10)
    }
    private var title: String {
        switch panel {
        case .add: return "添加"
        case let .server(id, _): return id == nil ? "新增服务器" : "编辑服务器"
        case let .group(original): return original == nil ? "新建分组" : "重命名分组"
        case let .serverActions(id): return model.servers.first { $0.id == id }?.name ?? "服务器"
        case let .groupActions(group): return group
        }
    }
    private func menuItem(_ title: String, icon: String, shortcut: String?, action: @escaping () -> Void) -> some View {
        PaperAction(label: title, action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 18).foregroundStyle(Ink.sage)
                Text(title).font(.system(size: 12))
                Spacer()
            }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ServerEditor: View {
    @ObservedObject var model: Workspace
    let id: Int?
    let group: String
    @State private var name = ""
    @State private var host = ""
    @State private var chosenGroup = ""
    @State private var user = "deploy"
    @State private var port = "22"
    @State private var advanced = false
    @State private var error: String?
    @FocusState private var focused: Field?
    private enum Field { case name, host, user, port }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            field("名称") {
                TextField("例如 garden-api", text: $name).focused($focused, equals: .name)
                    .onSubmit { focused = .host }
            }
            field("地址") {
                TextField("IP 或主机名", text: $host).focused($focused, equals: .host).onSubmit(save)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("分组").font(.system(size: 10)).foregroundStyle(Ink.muted)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(model.groups, id: \.self) { group in
                            PaperAction(label: "选择分组\(group)", action: { chosenGroup = group }) {
                                HStack(spacing: 5) {
                                    Text(group).lineLimit(1)
                                    Spacer(minLength: 0)
                                    if chosenGroup == group { Image(systemName: "checkmark").font(.system(size: 9)) }
                                }.font(.system(size: 11)).padding(.horizontal, 10).frame(height: 31)
                                    .background(chosenGroup == group ? Ink.pale.opacity(0.8) : Ink.main.opacity(0.035), in: RoundedRectangle(cornerRadius: 7))
                            }
                        }
                    }
                }.scrollIndicators(.hidden).frame(height: min(100, CGFloat((model.groups.count + 1) / 2) * 37))
            }
            PaperAction(label: "展开或收起连接选项", action: { advanced.toggle() }) {
                HStack {
                    Text("连接选项").font(.system(size: 11))
                    Spacer()
                    Text("\(user) · \(port)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Ink.muted)
                    Image(systemName: advanced ? "chevron.up" : "chevron.down").font(.system(size: 8))
                }.padding(.vertical, 5)
            }
            if advanced {
                HStack(spacing: 12) {
                    field("用户名") { TextField("deploy", text: $user).focused($focused, equals: .user).onSubmit { focused = .port } }
                    field("端口") { TextField("22", text: $port).focused($focused, equals: .port).onSubmit(save) }.frame(width: 75)
                }
            }
            if let error { Text(error).font(.system(size: 11)).foregroundStyle(Ink.peach).fixedSize(horizontal: false, vertical: true) }
            HStack {
                Text("本次预览内有效 · 不会连接").font(.system(size: 9)).foregroundStyle(Ink.muted)
                Spacer()
                PaperAction(label: id == nil ? "添加服务器" : "保存服务器", action: save) {
                    Text(id == nil ? "添加" : "保存").font(.system(size: 12, weight: .medium)).foregroundStyle(Ink.sage)
                        .padding(.horizontal, 18).padding(.vertical, 9).background(Ink.pale, in: Capsule())
                }
            }.padding(.top, 3)
        }
        .onAppear {
            chosenGroup = group
            if let server = model.servers.first(where: { $0.id == id }) {
                name = server.name; host = server.host; chosenGroup = server.group; user = server.user; port = String(server.port)
            } else if model.searching {
                if model.query.contains(".") { host = model.query.trimmingCharacters(in: .whitespacesAndNewlines) }
                else { name = model.query.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            focused = name.isEmpty ? .name : .host
        }
    }
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(size: 10)).foregroundStyle(Ink.muted)
            content().textFieldStyle(.plain).font(.system(size: 12)).padding(10)
                .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Ink.line))
        }
    }
    private func save() { error = model.saveServer(id: id, name: name, host: host, group: chosenGroup, user: user, port: port) }
}

private struct GroupEditor: View {
    @ObservedObject var model: Workspace
    let original: String?
    @State private var name = ""
    @State private var error: String?
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField("分组名称", text: $name).textFieldStyle(.plain).font(.system(size: 13))
                .padding(11).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Ink.line)).focused($focused).onSubmit(save)
            if let error { Text(error).font(.system(size: 11)).foregroundStyle(Ink.peach) }
            HStack {
                Text("本次预览内有效").font(.system(size: 9)).foregroundStyle(Ink.muted)
                Spacer()
                PaperAction(label: original == nil ? "创建分组" : "保存分组名称", action: save) {
                    Text(original == nil ? "创建" : "保存").font(.system(size: 12, weight: .medium)).foregroundStyle(Ink.sage)
                        .padding(.horizontal, 18).padding(.vertical, 9).background(Ink.pale, in: Capsule())
                }
            }
        }.onAppear { name = original ?? "" }
            .task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                focused = true
            }
    }
    private func save() { error = model.saveGroup(original: original, name: name) }
}
