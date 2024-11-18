// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RadarSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "RadarSDK",
            targets: ["RadarSDK"]
        ),
        .library(
            name: "RadarSDKMotion",
            targets: ["RadarSDKMotion"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.25.0")
    ],
    targets: [
        .target(
            name: "RadarSDK",
            path: "RadarSDK",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath(".")
            ],
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ]
        ),
        .target(
            name: "RadarSDKMotion",
            dependencies: ["RadarSDK"],
            path: "RadarSDKMotion/RadarSDKMotion",
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath(".")
            ]
        )
    ]
)
