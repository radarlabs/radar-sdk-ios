//
//  RadarSDKTestFixture.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

/// Delivers `mockLocation` to the delegate on `requestLocation()`, like `CLLocationManagerMock`.
final class RequestLocationCLLocationManager: CLLocationManager, @unchecked Sendable {
    var mockLocation: CLLocation?

    override var location: CLLocation? { mockLocation }

    // The test host has no background location capability, so ignore this like the Objective-C mock.
    override var pausesLocationUpdatesAutomatically: Bool {
        get { false }
        set {}
    }

    override func requestLocation() {
        if let mockLocation {
            delegate?.locationManager?(self, didUpdateLocations: [mockLocation])
        }
    }
}

/// Carries completion handler results that include non-Sendable SDK models back to the test.
private struct UncheckedSendable<Value>: @unchecked Sendable {
    let value: Value
}

/// Calls `body` and waits until it passes a result to `resume`.
///
/// SDK models like `RadarEvent` aren't `Sendable`, but the test only reads them after the callback runs.
@MainActor
func awaitCompletion<Value>(_ body: (@escaping @Sendable (Value) -> Void) -> Void) async -> Value {
    let result = await withCheckedContinuation { (continuation: CheckedContinuation<UncheckedSendable<Value>, Never>) in
        body { value in
            continuation.resume(returning: UncheckedSendable(value: value))
        }
    }
    return result.value
}

private final class RadarSDKTestBundleToken {}

enum RadarSDKTestResources {
    static let publishableKey = "prj_test_pk_0000000000000000000000000000000000000000"

    /// A recent location in Manhattan with no altitude, matching the track fixtures.
    static func manhattanLocation() -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 40.78382, longitude: -73.97536),
            altitude: -1,
            horizontalAccuracy: 65,
            verticalAccuracy: -1,
            timestamp: Date()
        )
    }

    static func jsonDictionary(fromResource resource: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> [AnyHashable: Any] {
        let bundle = Bundle(for: RadarSDKTestBundleToken.self)
        let url = try #require(bundle.url(forResource: resource, withExtension: "json"), sourceLocation: sourceLocation)
        let data = try Data(contentsOf: url)
        return try #require(JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any], sourceLocation: sourceLocation)
    }
}

/// Initializes Radar and routes its API, location, and permission calls to mocks.
///
/// Suites that use it change the shared `Radar` singletons, so they must be nested in `RadarSerializedTests`.
@MainActor
struct RadarSDKTestFixture {
    let apiHelperMock: RadarAPIHelperMock
    let locationManagerMock = RequestLocationCLLocationManager()
    let permissionsHelperMock = RadarPermissionsHelperMock()

    init(apiHelperMock: RadarAPIHelperMock = RadarAPIHelperMock()) {
        self.apiHelperMock = apiHelperMock

        Radar.initialize(publishableKey: RadarSDKTestResources.publishableKey)
        RadarSettings.logLevel = .debug

        RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
        let locationManager = RadarLocationManager.sharedInstance()
        locationManager.locationManager = locationManagerMock
        locationManager.lowPowerLocationManager = locationManagerMock
        locationManagerMock.delegate = locationManager
        locationManager.permissionsHelper = permissionsHelperMock

        RadarReplayBuffer.sharedInstance.clearBuffer()
        RadarReplayBuffer.sharedInstance.cancelBatchTimer()

        // Clear user tags so tests don't interfere with each other.
        if let tags = Radar.getTags(), !tags.isEmpty {
            Radar.removeTags(tags)
        }

        RadarState.shared.altitudeAdjustments = nil
    }

    /// Simulates a location timeout without waiting for the real 20 second timer.
    func simulateLocationTimeout(sourceLocation: SourceLocation = #_sourceLocation) {
        guard let host = RadarLocationManager.sharedInstance() as? RadarLocationManagerSwiftHost else {
            Issue.record("RadarLocationManager doesn't conform to RadarLocationManagerSwiftHost", sourceLocation: sourceLocation)
            return
        }
        host.callCompletionHandlers(status: .errorLocation, location: nil)
    }
}
