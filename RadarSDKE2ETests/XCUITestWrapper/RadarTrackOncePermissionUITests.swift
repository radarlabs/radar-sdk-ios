import XCTest

final class RadarTrackOncePermissionUITests: RadarE2EPermissionUITestCase {
    func testTrackOnceAfterAllowWhileUsing() throws {
        let result = try run(.trackOnce, request: .whenInUse, answers: [.allowWhileUsing])
        assertForegroundSuccess(result)
        XCTAssertEqual(result.locationAuthorization, "authorizedWhenInUse")
    }

    func testTrackOnceAfterAllowOnce() throws {
        let result = try run(.trackOnce, request: .whenInUse, answers: [.allowOnce])
        assertForegroundSuccess(result)
        XCTAssertEqual(result.locationAuthorization, "authorizedWhenInUse")
    }

    func testTrackOnceAfterDontAllow() throws {
        let result = try run(.trackOnce, request: .whenInUse, answers: [.dontAllow])
        XCTAssertEqual(result.status, "ERROR_PERMISSIONS", "\(result)")
        XCTAssertEqual(result.trackRequestCount, 0)
        XCTAssertEqual(result.locationAuthorization, "denied")
    }

    func testTrackOnceAfterChangeToAlwaysAllow() throws {
        let result = try run(.trackOnce, request: .always, answers: [.allowWhileUsing, .changeToAlwaysAllow])
        assertForegroundSuccess(result)
        XCTAssertEqual(result.locationAuthorization, "authorizedAlways")
    }

    func testTrackOnceAfterKeepOnlyWhileUsing() throws {
        let result = try run(.trackOnce, request: .always, answers: [.allowWhileUsing, .keepOnlyWhileUsing])
        assertForegroundSuccess(result)
        XCTAssertEqual(result.locationAuthorization, "authorizedWhenInUse")
    }
}
