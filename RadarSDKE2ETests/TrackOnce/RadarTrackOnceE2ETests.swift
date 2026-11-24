import CoreLocation
import XCTest

@MainActor
final class RadarTrackOnceE2ETests: XCTestCase {
    private var sdk: RadarE2ESDK!

    override func setUp() async throws {
        let authorization = CLLocationManager().authorizationStatus
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else {
            throw RadarE2EFailure("Grant the test host location permission first. See RadarSDKE2ETests/README.md.")
        }
        sdk = RadarE2ESDK(configuration: try RadarE2EConfiguration())
    }

    override func tearDown() async throws {
        sdk?.reset()
    }

    func testTrackOnceSendsOneForegroundUpdate() async throws {
        let outcome = try await sdk.trackOnce()
        try sdk.assertForegroundSuccess(outcome)
    }

    func testTrackOnceWithHighAccuracySendsOneForegroundUpdate() async throws {
        let outcome = try await sdk.trackOnce(desiredAccuracy: .high)
        try sdk.assertForegroundSuccess(outcome)
    }
}
