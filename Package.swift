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
        .target(
            name: "RadarSDK",
            path: "RadarSDK",
            exclude: ["Info.plist", "RadarSDK.h"],
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath("Internal")
            ]
        ),
        .testTarget(
            name: "RadarSDKTests",
            dependencies: ["RadarSDK"],
            path: "RadarSDKTests",
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/context.json"),
                .copy("Resources/events_verification.json"),
                .copy("Resources/geocode.json"),
                .copy("Resources/geocode_ip.json"),
                .copy("Resources/route_distance.json"),
                .copy("Resources/search_autocomplete.json"),
                .copy("Resources/search_geofences.json"),
                .copy("Resources/search_places.json"),
                .copy("Resources/track.json"),
            ]
        )
    ]
)
