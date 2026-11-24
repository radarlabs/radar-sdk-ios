import Foundation

/// Environment variables a UI test sets to tell the host app what to run.
enum RadarE2EEnvironment {
    static let scenario = "RADAR_E2E_SCENARIO"
    static let permissionRequest = "RADAR_E2E_PERMISSION_REQUEST"
}

/// A journey the host app can run, named by `RadarE2EEnvironment.scenario`.
enum RadarE2EScenario: String {
    case trackOnce
}

/// The location permission the host app requests before it runs a scenario.
enum RadarE2EPermissionRequest: String {
    case noRequest = "none"
    case whenInUse
    case always
}

/// What the host app reports to a UI test, JSON-encoded in the result label's accessibility value.
struct RadarE2EResult: Codable {
    let status: String
    let userIdMatches: Bool
    let foreground: Bool?
    let source: String?
    let trackRequestCount: Int
    let failure: String?

    static func failed(_ message: String) -> RadarE2EResult {
        RadarE2EResult(status: "FAILED", userIdMatches: false, foreground: nil, source: nil, trackRequestCount: 0, failure: message)
    }
}
