import XCTest

final class RadarTrackOnceE2ETests: XCTestCase {
    @MainActor
    func testTrackOnceSendsOneForegroundLocationUpdate() async throws {
        try await RadarTrackOnceScenario.run(configuration: RadarE2EConfiguration())
    }
}
