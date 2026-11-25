import XCTest

final class RadarE2ETrackLogTests: XCTestCase {
    private static let host = "https://api.example.com"
    private static let foregroundUser = """
        {"userId":"ios-e2e-1","foreground":true,"source":"FOREGROUND_LOCATION","location":{"type":"Point","coordinates":[-73.97536,40.78382]}}
        """

    private func requestLine(_ path: String, method: String = "POST", host: String = host, params: String = "{}") -> String {
        "📍 Radar API request | method = \(method); url = \(host)\(path); headers = {\"Authorization\":\"test-header-value\"}; params = \(params) | backgroundTimeRemaining = 29.5"
    }

    private func responseLine(_ path: String, statusCode: Int = 200, res: String = "{}") -> String {
        "📍 Radar API response | method = POST; url = \(Self.host)\(path); statusCode = \(statusCode); latency = 0.25; res = \(res) | backgroundTimeRemaining = 29.5"
    }

    private func makeLog() -> RadarE2ETrackLog {
        RadarE2ETrackLog(host: Self.host)
    }

    func testRecordKeepsTrackRequestToConfiguredHost() {
        var log = makeLog()
        log.record(requestLine("/v1/track"))
        XCTAssertEqual(log.exchanges.count, 1)
    }

    func testRecordKeepsReplayRequestAsTrackRequest() {
        var log = makeLog()
        log.record(requestLine("/v1/track/replay"))
        XCTAssertEqual(log.exchanges.count, 1)
    }

    func testRecordIgnoresRequestsToOtherPaths() {
        var log = makeLog()
        log.record(requestLine("/v1/config", method: "GET"))
        log.record(requestLine("/v1/track-other"))
        XCTAssertEqual(log.exchanges.count, 0)
    }

    func testRecordIgnoresTrackRequestsToOtherHosts() {
        var log = makeLog()
        log.record(requestLine("/v1/track", host: "https://other.example.com"))
        XCTAssertEqual(log.exchanges.count, 0)
    }

    func testRecordDecodesRequestParams() {
        var log = makeLog()
        log.record(
            requestLine(
                "/v1/track",
                params: #"{"userId":"ios-e2e-1","foreground":true,"source":"FOREGROUND_LOCATION","latitude":40.78382,"longitude":-73.97536}"#))
        let request = log.exchanges.first?.request
        XCTAssertEqual(request?.userId, "ios-e2e-1")
        XCTAssertEqual(request?.foreground, true)
        XCTAssertEqual(request?.source, "FOREGROUND_LOCATION")
        XCTAssertEqual(request?.latitude, 40.78382)
        XCTAssertEqual(request?.longitude, -73.97536)
    }

    func testRecordPairsResponseWithItsRequest() {
        var log = makeLog()
        log.record(requestLine("/v1/track"))
        log.record(responseLine("/v1/track", res: #"{"meta":{"code":200},"user":\#(Self.foregroundUser)}"#))
        let exchange = log.exchanges.first
        XCTAssertEqual(exchange?.statusCode, 200)
        XCTAssertEqual(exchange?.response?.meta?.code, 200)
        XCTAssertEqual(exchange?.response?.user?.userId, "ios-e2e-1")
        XCTAssertEqual(exchange?.response?.user?.foreground, true)
        XCTAssertEqual(exchange?.response?.user?.source, "FOREGROUND_LOCATION")
        XCTAssertEqual(exchange?.response?.user?.location?.coordinates, [-73.97536, 40.78382])
    }

    func testRecordLeavesMetaCodeEmptyWhenResponseHasNone() {
        var log = makeLog()
        log.record(requestLine("/v1/track"))
        log.record(responseLine("/v1/track", res: #"{"user":\#(Self.foregroundUser)}"#))
        XCTAssertNil(log.exchanges.first?.response?.meta?.code)
        XCTAssertEqual(log.exchanges.first?.response?.user?.userId, "ios-e2e-1")
    }

    func testRecordKeepsStatusCodeWhenResponseBodyIsNotAnObject() {
        var log = makeLog()
        log.record(requestLine("/v1/track"))
        log.record(responseLine("/v1/track", statusCode: 500, res: "not json"))
        XCTAssertEqual(log.exchanges.first?.statusCode, 500)
        XCTAssertNil(log.exchanges.first?.response)
    }

    func testRecordIgnoresResponseWithoutRequest() {
        var log = makeLog()
        log.record(responseLine("/v1/track"))
        XCTAssertEqual(log.exchanges.count, 0)
    }

    func testRecordPairsResponseDeliveredBeforeItsRequest() {
        var log = makeLog()
        log.record(responseLine("/v1/track", res: #"{"user":\#(Self.foregroundUser)}"#))
        log.record(requestLine("/v1/track"))
        XCTAssertEqual(log.exchanges.first?.statusCode, 200)
        XCTAssertEqual(log.exchanges.first?.response?.user?.userId, "ios-e2e-1")
    }

    func testExchangesSinceSkipsEarlierExchanges() {
        var log = makeLog()
        log.record(requestLine("/v1/track"))
        log.record(requestLine("/v1/track/replay"))
        XCTAssertEqual(log.exchanges(since: 1).map(\.url), ["\(Self.host)/v1/track/replay"])
    }
}
