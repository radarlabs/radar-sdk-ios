//
//  RadarPublicAPICompatibilityTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
// Deliberately not `@testable`: this file only sees what customers see, so a member that loses
// `public`, or changes its name, type, or nullability, stops this file from compiling.
import RadarSDK
import Testing

// MARK: - Compile-time contract

// Swift call shapes that compiled against the 3.41.0 Objective-C headers of the classes now
// implemented in Swift. These functions are never called; compiling them is the check. The
// explicit type annotations are the point. Intentionally dropped in the move to Swift: public
// `init()` on SDK-vended models, subclassing them, and RadarSdkConfiguration (never public API).

private func chain(_ chain: RadarChain) {
    let _: String = chain.slug
    let _: String = chain.name
    let _: String? = chain.externalId
    let _: [AnyHashable: Any]? = chain.metadata
    var dictionary = chain.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    let _: [[AnyHashable: Any]]? = RadarChain.array(for: [chain])
}

private func coordinate(_ coordinate: RadarCoordinate) {
    let _: CLLocationCoordinate2D = coordinate.coordinate
    var dictionary = coordinate.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    let _: RadarCoordinate? = RadarCoordinate(coordinate: CLLocationCoordinate2D())
}

private func geometries(_ circle: RadarCircleGeometry, _ polygon: RadarPolygonGeometry) {
    let _: RadarGeofenceGeometry = circle
    let _: RadarCoordinate = circle.center
    let _: Double = circle.radius
    let _: [RadarCoordinate]? = polygon._coordinates
    let _: RadarCoordinate = polygon.center
    let _: Double = polygon.radius
}

private func fraud(_ fraud: RadarFraud) {
    let _: [Bool] = [
        fraud.passed, fraud.bypassed, fraud.verified, fraud.proxy, fraud.mocked, fraud.compromised, fraud.jumped,
        fraud.inaccurate, fraud.sharing, fraud.blocked,
    ]
    let _: [AnyHashable: Any] = fraud.dictionaryValue()
}

private func initializeOptions() {
    let options = RadarInitializeOptions()
    options.autoLogNotificationConversions = true
    options.autoHandleNotificationDeepLinks = true
    options.silentPush = true
    options.trackVerifiedAutoFailover = true
    options.networkTimeoutInterval = 1
    options.ipChangeDebounceInterval = 1
    let _: [AnyHashable: Any] = options.dictionaryValue()
    let dictionary: [AnyHashable: Any] = [:]
    _ = RadarInitializeOptions(dict: dictionary)
    Radar.initialize(publishableKey: "", options: options)
}

private func operatingHours(_ operatingHours: RadarOperatingHours) {
    let _: [String: [[String]]] = operatingHours.hours
}

private func revealRisk(_ token: RadarRevealRiskToken) {
    let _: String = token._id
    let _: String? = token.token
    let _: Date? = token.expiresAt
    let _: NSNumber? = token.expiresIn
    let _: RadarRevealRiskLevel = token.risk.level
    let _: [String] = token.risk.reasons
    var dictionary = token.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    switch token.risk.level {
    case .none, .low, .medium, .high: break
    @unknown default: break
    }
    let _: RadarRevealRiskLevel? = RadarRevealRiskLevel(rawValue: 1)

    if let ipAddress = token.network.ipAddress {
        let _: NSNumber? = ipAddress.latitude
        let _: NSNumber? = ipAddress.longitude
        let _: Bool = ipAddress.stateAllowed
        let _: Bool = ipAddress.countryAllowed
        let _: [NSNumber]? = ipAddress.geometry?.coordinates
    }
    if let privacy = token.network.privacy {
        let _: [Bool] = [privacy.hosting, privacy.proxy, privacy.relay, privacy.tor, privacy.vpn, privacy.residentialProxy]
    }
}

private func routes(_ route: RadarRoute, _ distance: RadarRouteDistance, _ duration: RadarRouteDuration) {
    let _: RadarRouteDistance = route.distance
    let _: RadarRouteDuration = route.duration
    let _: RadarRouteGeometry = route.geometry
    let _: [RadarCoordinate]? = route.geometry.coordinates
    let _: [AnyHashable: Any] = route.dictionaryValue()
    let _: Double = distance.value
    let _: String = distance.text
    var dictionary = distance.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    let _: Double = duration.value
    let _: String = duration.text
    let _: [AnyHashable: Any] = route.geometry.dictionaryValue()
    let _: String = RadarRouteModeUtils.stringForMode(.car)
}

private func timeZone(_ timeZone: RadarTimeZone) {
    let _: String = timeZone._id
    let _: String = timeZone.name
    let _: String = timeZone.code
    let _: Date = timeZone.currentTime
    let _: Int32 = timeZone.utcOffset
    let _: Int32 = timeZone.dstOffset
    let _: [AnyHashable: Any] = timeZone.dictionaryValue()
}

private func trip(_ trip: RadarTrip) {
    let _: String = trip._id
    let _: String? = trip.externalId
    let _: [AnyHashable: Any]? = trip.metadata
    let _: String? = trip.destinationGeofenceTag
    let _: String? = trip.destinationGeofenceExternalId
    let _: RadarCoordinate? = trip.destinationLocation
    let _: RadarRouteMode = trip.mode
    let _: Float = trip.etaDistance
    let _: Float = trip.etaDuration
    let _: RadarTripStatus = trip.status
    let _: [RadarTripOrder]? = trip.orders
    let _: [RadarTripLeg]? = trip.legs
    let _: String? = trip.currentLegId
    let _: [AnyHashable: Any] = trip.dictionaryValue()
    let _: RadarTrip? = RadarTrip(object: [:] as [String: Any])
}

private func tripLeg() {
    let leg = RadarTripLeg(destinationGeofenceTag: nil, destinationGeofenceExternalId: nil)
    _ = RadarTripLeg(destinationGeofenceId: "")
    _ = RadarTripLeg(address: "")
    _ = RadarTripLeg(coordinates: CLLocationCoordinate2D())
    _ = RadarTripLeg()
    let _: String? = leg._id
    let _: RadarTripLegStatus = leg.status
    let _: RadarTripLegDestinationType = leg.destinationType
    let _: Date? = leg.createdAt
    let _: Date? = leg.updatedAt
    let _: Float = leg.etaDuration
    let _: Float = leg.etaDistance
    leg.destinationGeofenceTag = nil
    leg.destinationGeofenceExternalId = nil
    leg.destinationGeofenceId = nil
    leg.address = nil
    leg.coordinates = CLLocationCoordinate2D()
    let _: Bool = leg.hasCoordinates
    leg.arrivalRadius = 1
    leg.stopDuration = 1
    leg.metadata = nil
    let dictionary: [AnyHashable: Any]? = nil
    _ = RadarTripLeg(from: dictionary)
    let _: [RadarTripLeg]? = RadarTripLeg.legs(from: nil)
    let _: [AnyHashable: Any] = leg.dictionaryValue()
    let _: [[AnyHashable: Any]]? = RadarTripLeg.array(for: [leg])
    let _: String = RadarTripLeg.string(for: RadarTripLegStatus.pending)
    let _: RadarTripLegStatus = RadarTripLeg.status(for: "")
    let _: String = RadarTripLeg.string(for: RadarTripLegDestinationType.address)
    let _: RadarTripLegDestinationType = RadarTripLeg.destinationType(for: "")
}

private func tripOptions() {
    let options = RadarTripOptions(externalId: "", destinationGeofenceTag: nil, destinationGeofenceExternalId: nil)
    _ = RadarTripOptions(
        externalId: "", destinationGeofenceTag: nil, destinationGeofenceExternalId: nil, scheduledArrivalAt: nil)
    _ = RadarTripOptions(
        externalId: "", destinationGeofenceTag: nil, destinationGeofenceExternalId: nil, scheduledArrivalAt: nil,
        startTracking: true)
    _ = RadarTripOptions()
    let _: String = options.externalId
    options.externalId = ""
    options.metadata = nil
    options.destinationGeofenceTag = nil
    options.destinationGeofenceExternalId = nil
    options.scheduledArrivalAt = nil
    options.mode = .car
    options.approachingThreshold = 1
    options.startTracking = true
    options.legs = nil
    let dictionary: [AnyHashable: Any] = [:]
    _ = RadarTripOptions(from: dictionary)
    let _: [AnyHashable: Any] = options.dictionaryValue()
    Radar.startTrip(options: options)
}

private func tripOrder(_ order: RadarTripOrder) {
    let _: String = order._id
    let _: String? = order.guid
    let _: String? = order.handoffMode
    let _: RadarTripOrderStatus = order.status
    let _: Date? = order.firedAt
    let _: NSNumber? = order.firedAttempts
    let _: String? = order.firedReason
    let _: Date = order.updatedAt
    let _: [AnyHashable: Any] = order.dictionaryValue()
    let _: RadarTripOrder? = RadarTripOrder(object: 1)
    let _: [RadarTripOrder]? = RadarTripOrder.orders(from: 1)
    let _: [[AnyHashable: Any]]? = RadarTripOrder.array(for: nil)
}

// MARK: - Runtime checks that only need public API

@Suite struct RadarPublicAPICompatibilityTests {

    @Test func coordinateInitializerIsFailable() {
        // Conditional binding only compiles when the initializer is failable.
        guard let coordinate = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: 40, longitude: -74))
        else {
            Issue.record("RadarCoordinate(coordinate:) returned nil")
            return
        }
        #expect(coordinate.coordinate.latitude == 40)
    }

    @Test func tripOrderInitializerIsFailable() {
        guard
            let order = RadarTripOrder(
                id: "order-id",
                guid: nil,
                handoffMode: nil,
                status: .pending,
                firedAt: nil,
                firedAttempts: nil,
                firedReason: nil,
                updatedAt: Date()
            )
        else {
            Issue.record("RadarTripOrder(id:...) returned nil")
            return
        }
        let dictionaries: [[AnyHashable: Any]]? = RadarTripOrder.array(for: [order])
        #expect(dictionaries?.count == 1)
    }

    @Test func tripOptionsExternalIdIsNonOptionalString() {
        let options = RadarTripOptions(
            externalId: "trip-id",
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil
        )
        // Inference, not an annotation: `String!` would satisfy `let x: String = ...` but infers
        // `String?` here, so `.isEmpty` would not compile.
        let externalId = options.externalId
        #expect(!externalId.isEmpty)
        #expect(externalId.count == 7)
    }
}
