import CoreLocation

@testable import RadarSDK

struct RadarE2EFailure: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}

/// Drives the Radar SDK against the live API. Create one per test, and call `reset()` when the test ends.
///
/// Failure messages never include log lines, headers or the publishable key. They name the field that mismatched and its value.
@MainActor
final class RadarE2ESDK: NSObject, RadarDelegate {
    /// What `trackOnce` reported, plus the track requests and responses the SDK logged while it ran.
    struct TrackOnceOutcome: @unchecked Sendable {  // RadarUser and RadarEvent are not Sendable; the outcome stays on the main actor.
        let status: RadarStatus
        let location: CLLocation?
        let events: [RadarEvent]?
        let user: RadarUser?
        var trackExchanges: [RadarE2ETrackLog.Exchange] = []

        var trackRequestCount: Int { trackExchanges.count }
    }

    let userID = "ios-e2e-" + UUID().uuidString

    private static let trackOnceTimeoutSeconds = 25
    private static let fixtureToleranceMeters: CLLocationDistance = 100
    private static let foregroundSource = "FOREGROUND_LOCATION"
    private var trackLog: RadarE2ETrackLog

    init(configuration: RadarE2EConfiguration) {
        let absoluteString = configuration.baseURL.absoluteString
        let host = absoluteString.hasSuffix("/") ? String(absoluteString.dropLast()) : absoluteString
        trackLog = RadarE2ETrackLog(host: host)
        super.init()
        // The SDK persists its cached location permission, log level and config across launches. Start each run clean.
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        UserDefaults.standard.set(host, forKey: "radar-host")
        // The override forces debug logs regardless of the server's config and keeps the SDK from printing them, headers and key included, to the console.
        RadarLogger.shared.logLevelOverride = .debug
        Radar.setDelegate(self)
        Radar.initialize(publishableKey: configuration.publishableKey)
        Radar.setUserId(userID)
    }

    nonisolated func didLog(message: String) {
        MainActor.assumeIsolated {
            trackLog.record(message)
        }
    }

    /// Calls `Radar.trackOnce`, waits for its callback, then for the SDK's pending log lines to reach the delegate.
    /// Throws if the callback never arrives. A request or response the SDK did not log shows up in `trackExchanges`, not as a throw.
    func trackOnce(desiredAccuracy: RadarTrackingOptionsDesiredAccuracy = .medium, beacons: Bool = false) async throws -> TrackOnceOutcome {
        let exchangesBefore = trackLog.exchanges.count
        let (callbacks, callback) = AsyncStream<TrackOnceOutcome>.makeStream(bufferingPolicy: .bufferingNewest(1))
        // Not a sleeping Task: a cancelled `Task.sleep` throws CancellationError, and XCTest then reports that in place of the test's own failure.
        let timeout = DispatchWorkItem { callback.finish() }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Self.trackOnceTimeoutSeconds), execute: timeout)
        defer { timeout.cancel() }

        Radar.trackOnce(desiredAccuracy: desiredAccuracy, beacons: beacons) { status, location, events, user in
            callback.yield(TrackOnceOutcome(status: status, location: location, events: events, user: user))
            callback.finish()
        }
        var iterator = callbacks.makeAsyncIterator()
        guard var outcome = await iterator.next() else {
            throw RadarE2EFailure("trackOnce did not call back within \(Self.trackOnceTimeoutSeconds) seconds.")
        }
        await RadarLogger.shared.awaitPendingLogs()
        outcome.trackExchanges = trackLog.exchanges(since: exchangesBefore)
        return outcome
    }

    /// Throws unless `trackOnce` succeeded and the SDK callback, the logged track request and the logged server response all agree on a foreground update for this user at the fixture.
    func assertForegroundSuccess(_ outcome: TrackOnceOutcome) throws {
        try assertCallback(outcome)
        guard outcome.trackExchanges.count == 1, let exchange = outcome.trackExchanges.first else {
            throw RadarE2EFailure("Expected one track request, observed \(outcome.trackRequestCount).")
        }
        try assertRequest(exchange)
        try assertResponse(exchange)
    }

    /// Runs a named scenario and summarizes it for a UI test. When `trackOnce` succeeds, a failed `assertForegroundSuccess` is reported in `failure`.
    func run(_ scenario: RadarE2EScenario) async -> RadarE2EResult {
        switch scenario {
        case .trackOnce:
            do {
                let outcome = try await trackOnce()
                var failure: String?
                if outcome.status == .success {
                    do {
                        try assertForegroundSuccess(outcome)
                    } catch {
                        failure = error.localizedDescription
                    }
                }
                return result(for: outcome, failure: failure)
            } catch {
                return .failed(error.localizedDescription)
            }
        }
    }

    func reset() {
        Radar.stopTracking()
        Radar.setDelegate(nil)
        RadarLogger.shared.logLevelOverride = nil
    }

    private func assertCallback(_ outcome: TrackOnceOutcome) throws {
        try check(outcome.status == .success, "trackOnce returned \(Radar.stringForStatus(outcome.status)).")
        guard let user = outcome.user else { throw RadarE2EFailure("trackOnce returned no user.") }
        try check(user.userId == userID, "The SDK user's userId was \(user.userId ?? "missing"), not \(userID).")
        try check(isNearFixture(user.location), "The SDK user's location was more than 100 m from the fixture.")
        try check(user.foreground, "The SDK user was not marked foreground.")
        try check(user.source == .foregroundLocation, "The SDK user's source was \(Radar.stringForLocationSource(user.source)), not \(Self.foregroundSource).")
        try check(!Radar.isTracking(), "Background tracking was on after trackOnce.")
    }

    private func assertRequest(_ exchange: RadarE2ETrackLog.Exchange) throws {
        guard let request = exchange.request else { throw RadarE2EFailure("The SDK did not log the track request params.") }
        try check(request.foreground == true, "The track request foreground was \(describe(request.foreground)), not true.")
        try check(request.source == Self.foregroundSource, "The track request source was \(describe(request.source)), not \(Self.foregroundSource).")
        try check(request.userId == userID, "The track request userId was \(describe(request.userId)), not \(userID).")
        try check(
            isNearFixture(latitude: request.latitude, longitude: request.longitude),
            "The track request location was \(describe(request.latitude)), \(describe(request.longitude)), more than 100 m from the fixture.")
    }

    private func assertResponse(_ exchange: RadarE2ETrackLog.Exchange) throws {
        guard let statusCode = exchange.statusCode else { throw RadarE2EFailure("The SDK logged the track request but no track response.") }
        try check(statusCode == 200, "The track response statusCode was \(statusCode), not 200.")
        guard let user = exchange.response?.user else { throw RadarE2EFailure("The SDK did not log a track response with a user.") }
        if let code = exchange.response?.meta?.code {
            try check(code == 200, "The track response meta.code was \(code), not 200.")
        }
        try check(user.userId == userID, "The track response user.userId was \(describe(user.userId)), not \(userID).")
        try check(user.foreground == true, "The track response user.foreground was \(describe(user.foreground)), not true.")
        try check(user.source == Self.foregroundSource, "The track response user.source was \(describe(user.source)), not \(Self.foregroundSource).")
        let coordinates = user.location?.coordinates ?? []
        try check(
            coordinates.count == 2 && isNearFixture(latitude: coordinates[1], longitude: coordinates[0]),
            "The track response user.location.coordinates were \(coordinates), more than 100 m from the fixture.")
    }

    private func result(for outcome: TrackOnceOutcome, failure: String?) -> RadarE2EResult {
        RadarE2EResult(
            status: Radar.stringForStatus(outcome.status),
            userIdMatches: outcome.user?.userId == userID,
            foreground: outcome.user?.foreground,
            source: outcome.user.map { Radar.stringForLocationSource($0.source) },
            trackRequestCount: outcome.trackRequestCount,
            failure: failure)
    }

    private func isNearFixture(_ location: CLLocation) -> Bool {
        location.distance(from: RadarE2EConfiguration.location) < Self.fixtureToleranceMeters
    }

    private func isNearFixture(latitude: Double?, longitude: Double?) -> Bool {
        guard let latitude, let longitude else { return false }
        return isNearFixture(CLLocation(latitude: latitude, longitude: longitude))
    }

    private func describe<T>(_ value: T?) -> String {
        value.map { "\($0)" } ?? "missing"
    }

    private func check(_ condition: Bool, _ message: @autoclosure () -> String) throws {
        guard condition else { throw RadarE2EFailure(message()) }
    }
}
