// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyProject",
    dependencies: [
        .package(url: "https//github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "MyProject", dependencies: ["NIO", "NIOSSL"]),
    ]
)
