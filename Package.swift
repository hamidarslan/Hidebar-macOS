// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Hidebar",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Hidebar", targets: ["Hidebar"])],
    targets: [
        .target(name: "HidebarCore"),
        .executableTarget(name: "Hidebar", dependencies: ["HidebarCore"]),
        .testTarget(name: "HidebarCoreTests", dependencies: ["HidebarCore"])
    ]
)
