import XCTest

final class RadarTrackOncePermissionUITests: XCTestCase {
    @MainActor
    func testTrackOnceSendsOneForegroundLocationUpdateAfterGrantingPermission() throws {
        let environment = ProcessInfo.processInfo.environment
        let host = XCUIApplication(bundleIdentifier: "io.radar.RadarE2ETestHost")
        host.launchEnvironment = [
            "RADAR_E2E_RUN_TRACK_ONCE": "1",
            "RADAR_E2E_BASE_URL": try XCTUnwrap(environment["RADAR_E2E_BASE_URL"], "Set RADAR_E2E_BASE_URL."),
            "RADAR_E2E_PUBLISHABLE_KEY": try XCTUnwrap(environment["RADAR_E2E_PUBLISHABLE_KEY"], "Set RADAR_E2E_PUBLISHABLE_KEY."),
        ]
        host.launch()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowLocation = springboard.alerts.buttons.matching(
            NSPredicate(format: "label IN %@", ["Allow While Using App", "Allow While Using the App"])
        ).firstMatch
        let result = host.staticTexts["radar-e2e-result"]
        let finished = NSPredicate(format: "exists == true AND label != %@", "Running")
        let permissionOrResult = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                allowLocation.exists || finished.evaluate(with: result)
            }, object: nil)
        guard XCTWaiter.wait(for: [permissionOrResult], timeout: 20) == .completed else {
            XCTFail("The host showed neither the location prompt nor a test result.")
            return
        }
        if allowLocation.exists {
            allowLocation.tap()
        }

        let completed = XCTNSPredicateExpectation(predicate: finished, object: result)
        guard XCTWaiter.wait(for: [completed], timeout: 40) == .completed else {
            XCTFail("The host did not report a trackOnce result.")
            return
        }
        XCTAssertEqual(result.label, "Passed")
    }
}
