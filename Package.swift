// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "ShellX", platforms: [.macOS(.v14)], products: [.executable(name: "ShellX", targets: ["ShellX"])], targets: [.executableTarget(name: "ShellX", resources: [.process("Resources")])])
