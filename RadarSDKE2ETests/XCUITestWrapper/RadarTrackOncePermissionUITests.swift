import XCTest

final class RadarTrackOncePermissionUITests: RadarE2EPermissionUITestCase {
    func testTrackOnceAfterAllowWhileUsing() throws {
        let result = try run(.trackOnce, request: .whenInUse, answers: [.allowWhileUsing])
        assertForegroundSuccess(result)
    }

    func testTrackOnceAfterAllowOnce() throws {
        let result = try run(.trackOnce, request: .whenInUse, answers: [.allowOnce])
        assertForegroundSuccess(result)
    }

    func testTrackOnceAfterDontAllow() throws {
        let result = try run(.trackOnce, request: .whenInUse, answers: [.dontAllow])
        XCTAssertEqual(result.status, "ERROR_PERMISSIONS", "\(result)")
        XCTAssertEqual(result.trackRequestCount, 0)
    }

    func testTrackOnceAfterChangeToAlwaysAllow() throws {
        let result = try run(.trackOnce, request: .always, answers: [.allowWhileUsing, .changeToAlwaysAllow])
        assertForegroundSuccess(result)
    }
}
