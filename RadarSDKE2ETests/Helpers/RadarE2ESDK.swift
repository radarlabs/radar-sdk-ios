import CoreLocation
import RadarSDK

struct RadarE2EFailure: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}

/// Drives the Radar SDK against the live API. Create one per test, and call `reset()` when the test ends.
@MainActor
final class RadarE2ESDK: NSObject, RadarDelegate {
    /// What `trackOnce` reported, plus the track requests the SDK logged while it ran.
    struct TrackOnceOutcome: @unchecked Sendable {  // RadarUser and RadarEvent are not Sendable; the outcome stays on the main actor.
        let status: RadarStatus
        let location: CLLocation?
        let events: [RadarEvent]?
        let user: RadarUser?
        let trackRequestCount: Int
    }

    let userID = "ios-e2e-" + UUID().uuidString

    private static let trackOnceTimeoutSeconds: UInt64 = 25
    private let trackRequestMarker: String
    private var loggedTrackRequests = 0

    init(configuration: RadarE2EConfiguration) {
        let absoluteString = configuration.baseURL.absoluteString
        let host = absoluteString.hasSuffix("/") ? String(absoluteString.dropLast()) : absoluteString
        trackRequestMarker = "method = POST; url = \(host)/v1/track"
        super.init()
        UserDefaults.standard.set(host, forKey: "radar-host")
        Radar.setLogLevel(.debug)
        Radar.setDelegate(self)
        Radar.initialize(publishableKey: configuration.publishableKey)
        Radar.setUserId(userID)
    }

    nonisolated func didLog(message: String) {
        MainActor.assumeIsolated {
            if message.contains(trackRequestMarker) {
                loggedTrackRequests += 1
            }
        }
    }

    /// Calls `Radar.trackOnce` and waits for its callback. Throws if the callback never arrives.
    func trackOnce(desiredAccuracy: RadarTrackingOptionsDesiredAccuracy = .medium, beacons: Bool = false) async throws -> TrackOnceOutcome {
        let requestsBefore = loggedTrackRequests
        let (outcomes, continuation) = AsyncStream<TrackOnceOutcome>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let timeout = Task {
            try await Task.sleep(nanoseconds: Self.trackOnceTimeoutSeconds * 1_000_000_000)
            continuation.finish()
        }
        defer { timeout.cancel() }

        Radar.trackOnce(desiredAccuracy: desiredAccuracy, beacons: beacons) { status, location, events, user in
            continuation.yield(
                TrackOnceOutcome(
                    status: status, location: location, events: events, user: user,
                    trackRequestCount: self.loggedTrackRequests - requestsBefore))
            continuation.finish()
        }
        var iterator = outcomes.makeAsyncIterator()
        guard let outcome = await iterator.next() else {
            throw RadarE2EFailure("trackOnce did not call back within \(Self.trackOnceTimeoutSeconds) seconds.")
        }
        return outcome
    }

    /// Throws unless `trackOnce` succeeded, the server echoed the foreground fixture update for this user, and the SDK sent one track request.
    func assertForegroundSuccess(_ outcome: TrackOnceOutcome) throws {
        try check(outcome.status == .success, "trackOnce returned \(Radar.stringForStatus(outcome.status)).")
        guard let user = outcome.user else { throw RadarE2EFailure("trackOnce returned no user.") }
        try check(user.userId == userID, "The server returned a different user ID.")
        try check(user.location.distance(from: RadarE2EConfiguration.location) < 100, "The server location was more than 100 m from the fixture.")
        try check(user.foreground, "The server did not mark the update as foreground.")
        try check(user.source == .foregroundLocation, "The server recorded \(Radar.stringForLocationSource(user.source)), not FOREGROUND_LOCATION.")
        try check(outcome.trackRequestCount == 1, "Expected one track request, observed \(outcome.trackRequestCount).")
        try check(!Radar.isTracking(), "Background tracking was on after trackOnce.")
    }

    /// Runs a named scenario and summarizes it for a UI test.
    func run(_ scenario: RadarE2EScenario) async -> RadarE2EResult {
        switch scenario {
        case .trackOnce:
            do {
                return result(for: try await trackOnce())
            } catch {
                return .failed(error.localizedDescription)
            }
        }
    }

    func reset() {
        Radar.stopTracking()
        Radar.setDelegate(nil)
    }

    private func result(for outcome: TrackOnceOutcome) -> RadarE2EResult {
        RadarE2EResult(
            status: Radar.stringForStatus(outcome.status),
            userIdMatches: outcome.user?.userId == userID,
            foreground: outcome.user?.foreground,
            source: outcome.user.map { Radar.stringForLocationSource($0.source) },
            trackRequestCount: outcome.trackRequestCount,
            failure: nil)
    }

    private func check(_ condition: Bool, _ message: @autoclosure () -> String) throws {
        guard condition else { throw RadarE2EFailure(message()) }
    }
}
