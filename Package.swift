// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RadarSDK",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "RadarSDK",
            targets: ["RadarSDK"]
        ),
        .library(
            name: "RadarSDKMotion",
            targets: ["RadarSDKMotion","RadarSDK"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RadarSDK",
            path: "RadarSDK",
            exclude: ["Info.plist", "RadarMotion.h", "RadarMotion.m"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath("."),
            ]
        ),
        .target(
           name: "RadarSDKMotion",
            dependencies: ["RadarSDK"],
            path: "RadarSDK",
            sources: ["RadarMotion.h", "RadarMotion.m"]
        ),
    ]
)
