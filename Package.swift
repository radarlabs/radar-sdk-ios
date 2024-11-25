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
            targets: ["RadarSDKMotion"]
        ),
        .library(
            name: "RadarSDKLocationPermission",
            targets: ["RadarSDKLocationPermission"]
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
        .target(
            name: "RadarSDKLocationPermission",
            dependencies: ["RadarSDK"],
            path: "RadarSDKLocationPermission/RadarSDKLocationPermission",
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath(".")
            ]
        )
    ]
)
