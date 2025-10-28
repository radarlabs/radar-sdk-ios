// swift-tools-version:5.3
import PackageDescription

let version = "3.24.2-beta.1"

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
            targets: ["RadarSDKMotion"]
        ),
        .library(
            name: "RadarSDKIndoors",
            targets: ["RadarSDKIndoors"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RadarSDK",
            path: "RadarSDK",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath(".")
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
        ),
        .binaryTarget(
            name: "RadarSDKIndoors",
            url: "https://github.com/radarlabs/radar-sdk-ios/releases/download/\(version)/RadarSDKIndoors.xcframework.zip"
        )
    ]
)
