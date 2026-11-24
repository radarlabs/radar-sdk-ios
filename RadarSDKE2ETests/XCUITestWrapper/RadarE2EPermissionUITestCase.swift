import XCTest

/// Base class for UI tests that run a `RadarE2ETestHost` scenario behind the system location prompts.
@MainActor
class RadarE2EPermissionUITestCase: XCTestCase {
    /// A button on the system location prompt. Each raw value is its label on the iOS 26.2 simulator.
    enum PromptAnswer: String {
        case allowOnce = "Allow Once"
        case allowWhileUsing = "Allow While Using App"
        case dontAllow = "Don\u{2019}t Allow"
        case changeToAlwaysAllow = "Change to Always Allow"
    }

    private static let promptTimeout: TimeInterval = 20
    private static let resultTimeout: TimeInterval = 60

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Resets the host's location permission, launches it, answers each prompt in order, and returns the scenario result.
    func run(_ scenario: RadarE2EScenario, request: RadarE2EPermissionRequest, answers: [PromptAnswer]) throws -> RadarE2EResult {
        let environment = ProcessInfo.processInfo.environment
        let host = XCUIApplication(bundleIdentifier: "io.radar.RadarE2ETestHost")
        host.resetAuthorizationStatus(for: .location)
        host.launchEnvironment = [
            RadarE2EEnvironment.scenario: scenario.rawValue,
            RadarE2EEnvironment.permissionRequest: request.rawValue,
            "RADAR_E2E_BASE_URL": try XCTUnwrap(environment["RADAR_E2E_BASE_URL"], "Set RADAR_E2E_BASE_URL."),
            "RADAR_E2E_PUBLISHABLE_KEY": try XCTUnwrap(environment["RADAR_E2E_PUBLISHABLE_KEY"], "Set RADAR_E2E_PUBLISHABLE_KEY."),
        ]
        host.launch()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for answer in answers {
            let button = springboard.alerts.buttons[answer.rawValue]
            XCTAssertTrue(button.waitForExistence(timeout: Self.promptTimeout), "The location prompt never offered \(answer).")
            button.tap()
        }

        let label = host.staticTexts["radar-e2e-result"]
        let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Done"), object: label)
        XCTAssertEqual(XCTWaiter.wait(for: [done], timeout: Self.resultTimeout), .completed, "The host did not report a result.")
        let json = try XCTUnwrap(label.value as? String, "The host reported no result value.")
        return try JSONDecoder().decode(RadarE2EResult.self, from: Data(json.utf8))
    }

    /// Fails unless `trackOnce` succeeded and the host's request, response and callback checks all passed.
    func assertForegroundSuccess(_ result: RadarE2EResult) {
        XCTAssertEqual(result.status, "SUCCESS", "\(result)")
        XCTAssertNil(result.failure)
        XCTAssertTrue(result.userIdMatches)
        XCTAssertEqual(result.foreground, true)
        XCTAssertEqual(result.source, "FOREGROUND_LOCATION")
        XCTAssertEqual(result.trackRequestCount, 1)
    }
}
