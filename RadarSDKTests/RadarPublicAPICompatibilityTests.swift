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
// explicit type checks are the point. Intentionally dropped in the move to Swift: public
// `init()` on SDK-vended models, subclassing them, and RadarSdkConfiguration (never public API).

// Compiles only when `value` is exactly `T`. Bind a member to a local before calling it: a
// `let _: String = x` annotation silently accepts an implicitly unwrapped `String!`, but a local
// infers `String?`, so `exactType(local, String.self)` catches that drift. For optional members,
// use `if let` instead, which fails to compile if the member stops being optional.
private func exactType<T>(_ value: T, _: T.Type) {}

private func chain(_ chain: RadarChain) {
    let value1 = chain.slug
    exactType(value1, String.self)
    let value2 = chain.name
    exactType(value2, String.self)
    if let value3 = chain.externalId { exactType(value3, String.self) }
    if let value4 = chain.metadata { exactType(value4, [AnyHashable: Any].self) }
    var dictionary = chain.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    if let value5 = RadarChain.array(for: [chain]) { exactType(value5, [[AnyHashable: Any]].self) }
}

private func coordinate(_ coordinate: RadarCoordinate) {
    let value6 = coordinate.coordinate
    exactType(value6, CLLocationCoordinate2D.self)
    var dictionary = coordinate.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    if let value7 = RadarCoordinate(coordinate: CLLocationCoordinate2D()) { exactType(value7, RadarCoordinate.self) }
}

private func geometries(_ circle: RadarCircleGeometry, _ polygon: RadarPolygonGeometry) {
    let value8 = circle
    exactType(value8, RadarGeofenceGeometry.self)
    let value9 = circle.center
    exactType(value9, RadarCoordinate.self)
    let value10 = circle.radius
    exactType(value10, Double.self)
    if let value11 = polygon._coordinates { exactType(value11, [RadarCoordinate].self) }
    let value12 = polygon.center
    exactType(value12, RadarCoordinate.self)
    let value13 = polygon.radius
    exactType(value13, Double.self)
}

private func fraud(_ fraud: RadarFraud) {
    let flags = [
        fraud.passed, fraud.bypassed, fraud.verified, fraud.proxy, fraud.mocked, fraud.compromised, fraud.jumped,
        fraud.inaccurate, fraud.sharing, fraud.blocked,
    ]
    exactType(flags, [Bool].self)
    let value14 = fraud.dictionaryValue()
    exactType(value14, [AnyHashable: Any].self)
}

private func initializeOptions() {
    let options = RadarInitializeOptions()
    options.autoLogNotificationConversions = true
    options.autoHandleNotificationDeepLinks = true
    options.silentPush = true
    options.trackVerifiedAutoFailover = true
    options.networkTimeoutInterval = 1
    options.ipChangeDebounceInterval = 1
    let value15 = options.dictionaryValue()
    exactType(value15, [AnyHashable: Any].self)
    let dictionary: [AnyHashable: Any] = [:]
    _ = RadarInitializeOptions(dict: dictionary)
    Radar.initialize(publishableKey: "", options: options)
}

private func operatingHours(_ operatingHours: RadarOperatingHours) {
    // Implicitly unwrapped on purpose: the 3.41.0 header left `hours` without nullability, so
    // callers both subscript it directly and bind it with `if let`.
    let value16 = operatingHours.hours
    exactType(value16, [String: [[String]]]?.self)
    _ = operatingHours.hours["mon"]
}

private func revealRisk(_ token: RadarRevealRiskToken) {
    let value17 = token._id
    exactType(value17, String.self)
    if let value18 = token.token { exactType(value18, String.self) }
    if let value19 = token.expiresAt { exactType(value19, Date.self) }
    if let value20 = token.expiresIn { exactType(value20, NSNumber.self) }
    let value21 = token.risk.level
    exactType(value21, RadarRevealRiskLevel.self)
    let value22 = token.risk.reasons
    exactType(value22, [String].self)
    var dictionary = token.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    switch token.risk.level {
    case .none, .low, .medium, .high: break
    @unknown default: break
    }
    if let value23 = RadarRevealRiskLevel(rawValue: 1) { exactType(value23, RadarRevealRiskLevel.self) }
    revealRiskNetwork(token.network)
}

private func revealRiskNetwork(_ network: RadarRevealRiskTokenNetwork) {
    if let ipAddress = network.ipAddress {
        if let value24 = ipAddress.latitude { exactType(value24, NSNumber.self) }
        if let value25 = ipAddress.longitude { exactType(value25, NSNumber.self) }
        let value26 = ipAddress.stateAllowed
        exactType(value26, Bool.self)
        let value27 = ipAddress.countryAllowed
        exactType(value27, Bool.self)
        if let value28 = ipAddress.geometry?.coordinates { exactType(value28, [NSNumber].self) }
    }
    if let privacy = network.privacy {
        let value29 = [privacy.hosting, privacy.proxy, privacy.relay, privacy.tor, privacy.vpn, privacy.residentialProxy]
        exactType(value29, [Bool].self)
    }
}

private func routes(_ route: RadarRoute, _ distance: RadarRouteDistance, _ duration: RadarRouteDuration) {
    let value30 = route.distance
    exactType(value30, RadarRouteDistance.self)
    let value31 = route.duration
    exactType(value31, RadarRouteDuration.self)
    let value32 = route.geometry
    exactType(value32, RadarRouteGeometry.self)
    if let value33 = route.geometry.coordinates { exactType(value33, [RadarCoordinate].self) }
    let value34 = route.dictionaryValue()
    exactType(value34, [AnyHashable: Any].self)
    let value35 = distance.value
    exactType(value35, Double.self)
    let value36 = distance.text
    exactType(value36, String.self)
    var dictionary = distance.dictionaryValue()
    dictionary[AnyHashable(1)] = 2
    let value37 = duration.value
    exactType(value37, Double.self)
    let value38 = duration.text
    exactType(value38, String.self)
    let value39 = route.geometry.dictionaryValue()
    exactType(value39, [AnyHashable: Any].self)
    let value40 = RadarRouteModeUtils.stringForMode(.car)
    exactType(value40, String.self)
}

private func timeZone(_ timeZone: RadarTimeZone) {
    let value41 = timeZone._id
    exactType(value41, String.self)
    let value42 = timeZone.name
    exactType(value42, String.self)
    let value43 = timeZone.code
    exactType(value43, String.self)
    let value44 = timeZone.currentTime
    exactType(value44, Date.self)
    let value45 = timeZone.utcOffset
    exactType(value45, Int32.self)
    let value46 = timeZone.dstOffset
    exactType(value46, Int32.self)
    let value47 = timeZone.dictionaryValue()
    exactType(value47, [AnyHashable: Any].self)
}

private func trip(_ trip: RadarTrip) {
    let value48 = trip._id
    exactType(value48, String.self)
    if let value49 = trip.externalId { exactType(value49, String.self) }
    if let value50 = trip.metadata { exactType(value50, [AnyHashable: Any].self) }
    if let value51 = trip.destinationGeofenceTag { exactType(value51, String.self) }
    if let value52 = trip.destinationGeofenceExternalId { exactType(value52, String.self) }
    if let value53 = trip.destinationLocation { exactType(value53, RadarCoordinate.self) }
    let value54 = trip.mode
    exactType(value54, RadarRouteMode.self)
    let value55 = trip.etaDistance
    exactType(value55, Float.self)
    let value56 = trip.etaDuration
    exactType(value56, Float.self)
    let value57 = trip.status
    exactType(value57, RadarTripStatus.self)
    if let value58 = trip.orders { exactType(value58, [RadarTripOrder].self) }
    if let value59 = trip.legs { exactType(value59, [RadarTripLeg].self) }
    if let value60 = trip.currentLegId { exactType(value60, String.self) }
    let value61 = trip.dictionaryValue()
    exactType(value61, [AnyHashable: Any].self)
    if let value62 = RadarTrip(object: [:] as [String: Any]) { exactType(value62, RadarTrip.self) }
}

private func tripLeg() {
    let leg = RadarTripLeg(destinationGeofenceTag: nil, destinationGeofenceExternalId: nil)
    _ = RadarTripLeg(destinationGeofenceId: "")
    _ = RadarTripLeg(address: "")
    _ = RadarTripLeg(coordinates: CLLocationCoordinate2D())
    _ = RadarTripLeg()
    if let value63 = leg._id { exactType(value63, String.self) }
    let value64 = leg.status
    exactType(value64, RadarTripLegStatus.self)
    let value65 = leg.destinationType
    exactType(value65, RadarTripLegDestinationType.self)
    if let value66 = leg.createdAt { exactType(value66, Date.self) }
    if let value67 = leg.updatedAt { exactType(value67, Date.self) }
    let value68 = leg.etaDuration
    exactType(value68, Float.self)
    let value69 = leg.etaDistance
    exactType(value69, Float.self)
    leg.destinationGeofenceTag = nil
    leg.destinationGeofenceExternalId = nil
    leg.destinationGeofenceId = nil
    leg.address = nil
    leg.coordinates = CLLocationCoordinate2D()
    let value70 = leg.hasCoordinates
    exactType(value70, Bool.self)
    leg.arrivalRadius = 1
    leg.stopDuration = 1
    leg.metadata = nil
    let dictionary: [AnyHashable: Any]? = nil
    _ = RadarTripLeg(from: dictionary)
    if let value71 = RadarTripLeg.legs(from: nil) { exactType(value71, [RadarTripLeg].self) }
    let value72 = leg.dictionaryValue()
    exactType(value72, [AnyHashable: Any].self)
    if let value73 = RadarTripLeg.array(for: [leg]) { exactType(value73, [[AnyHashable: Any]].self) }
    let value74 = RadarTripLeg.string(for: RadarTripLegStatus.pending)
    exactType(value74, String.self)
    let value75 = RadarTripLeg.status(for: "")
    exactType(value75, RadarTripLegStatus.self)
    let value76 = RadarTripLeg.string(for: RadarTripLegDestinationType.address)
    exactType(value76, String.self)
    let value77 = RadarTripLeg.destinationType(for: "")
    exactType(value77, RadarTripLegDestinationType.self)
}

private func tripOptions() {
    let options = RadarTripOptions(externalId: "", destinationGeofenceTag: nil, destinationGeofenceExternalId: nil)
    _ = RadarTripOptions(
        externalId: "", destinationGeofenceTag: nil, destinationGeofenceExternalId: nil, scheduledArrivalAt: nil)
    _ = RadarTripOptions(
        externalId: "", destinationGeofenceTag: nil, destinationGeofenceExternalId: nil, scheduledArrivalAt: nil,
        startTracking: true)
    _ = RadarTripOptions()
    let value78 = options.externalId
    exactType(value78, String.self)
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
    let value79 = options.dictionaryValue()
    exactType(value79, [AnyHashable: Any].self)
    Radar.startTrip(options: options)
}

private func tripOrder(_ order: RadarTripOrder) {
    let value80 = order._id
    exactType(value80, String.self)
    if let value81 = order.guid { exactType(value81, String.self) }
    if let value82 = order.handoffMode { exactType(value82, String.self) }
    let value83 = order.status
    exactType(value83, RadarTripOrderStatus.self)
    if let value84 = order.firedAt { exactType(value84, Date.self) }
    if let value85 = order.firedAttempts { exactType(value85, NSNumber.self) }
    if let value86 = order.firedReason { exactType(value86, String.self) }
    let value87 = order.updatedAt
    exactType(value87, Date.self)
    let value88 = order.dictionaryValue()
    exactType(value88, [AnyHashable: Any].self)
    if let value89 = RadarTripOrder(object: 1) { exactType(value89, RadarTripOrder.self) }
    if let value90 = RadarTripOrder.orders(from: 1) { exactType(value90, [RadarTripOrder].self) }
    if let value91 = RadarTripOrder.array(for: nil) { exactType(value91, [[AnyHashable: Any]].self) }
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
