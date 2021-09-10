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
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "RadarSDK",
            path: "dist/RadarSDK.xcframework"
        )
    ]
)