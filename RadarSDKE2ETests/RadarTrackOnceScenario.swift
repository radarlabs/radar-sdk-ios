import CoreLocation
import RadarSDK

@MainActor
enum RadarTrackOnceScenario {
    private struct TrackPayload: Decodable {
        let foreground: Bool
        let source: String
        let userId: String
        let latitude: Double
        let longitude: Double
    }

    private struct TrackResult: Sendable {
        let status: RadarStatus
        let location: CLLocation?
        let userID: String?
    }

    static func run(configuration: RadarE2EConfiguration) async throws {
        try check(CLLocationManager().authorizationStatus == .authorizedWhenInUse, "Grant the test host When In Use permission.")

        let relay = try RadarE2EHTTPRelay(upstream: configuration.baseURL)
        defer { relay.stop() }

        let defaults = UserDefaults.standard
        let hostKey = "radar-host"
        let priorHost = defaults.object(forKey: hostKey)
        defaults.set(relay.host, forKey: hostKey)
        defer {
            Radar.setUserId(nil)
            defaults.set(priorHost, forKey: hostKey)
        }

        Radar.initialize(publishableKey: configuration.publishableKey)
        let userID = "ios-e2e-" + UUID().uuidString
        Radar.setUserId(userID)
        try check(!Radar.isTracking(), "Background tracking was on before trackOnce.")

        let (results, continuation) = AsyncStream<TrackResult>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let timeout = Task {
            try await Task.sleep(nanoseconds: 25_000_000_000)
            continuation.finish()
        }
        defer { timeout.cancel() }

        Radar.trackOnce { status, location, _, user in
            continuation.yield(TrackResult(status: status, location: location, userID: user?.userId))
            continuation.finish()
        }
        var iterator = results.makeAsyncIterator()
        guard let result = await iterator.next() else {
            throw Failure(description: "trackOnce did not call back within 25 seconds.")
        }
        try check(result.status == .success, "trackOnce returned \(Radar.stringForStatus(result.status)).")
        try check(result.userID == userID, "The SDK returned a different user ID.")
        try check(isNearFixture(result.location), "The SDK location was missing or more than 100 m from the fixture.")

        let exchanges = relay.tracks
        guard exchanges.count == 1, let exchange = exchanges.first else {
            throw Failure(description: "Expected one track request, observed \(exchanges.count).")
        }
        try check(exchange.statusCode == 200, "Expected HTTP 200, received \(exchange.statusCode.map(String.init) ?? "no status").")
        let payload = try JSONDecoder().decode(TrackPayload.self, from: exchange.body)
        try check(payload.foreground, "The track request was not marked foreground.")
        try check(payload.source == "FOREGROUND_LOCATION", "The track request did not use FOREGROUND_LOCATION.")
        try check(payload.userId == userID, "The track request contained a different user ID.")
        try check(isNearFixture(CLLocation(latitude: payload.latitude, longitude: payload.longitude)), "The track request location was more than 100 m from the fixture.")
        try check(!Radar.isTracking(), "Background tracking was on after trackOnce.")
    }

    private static func isNearFixture(_ location: CLLocation?) -> Bool {
        location.map { $0.distance(from: RadarE2EConfiguration.location) < 100 } ?? false
    }

    private static func check(_ condition: Bool, _ description: @autoclosure () -> String) throws {
        guard condition else { throw Failure(description: description()) }
    }

    private struct Failure: LocalizedError {
        let description: String
        var errorDescription: String? { description }
    }
}
