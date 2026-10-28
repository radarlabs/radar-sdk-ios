//
//  RadarSDKTestAssertions.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// Checks that models parsed from the JSON fixtures have their required fields.
// Each helper takes the caller's source location so failures point at the test.

func expectGeofencesOk(_ geofences: [RadarGeofence]?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(geofences != nil, sourceLocation: sourceLocation)
    for geofence in geofences ?? [] {
        expectGeofenceOk(geofence, sourceLocation: sourceLocation)
    }
}

func expectGeofenceOk(_ geofence: RadarGeofence?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let geofence else {
        Issue.record("geofence is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(geofence.tag != nil, sourceLocation: sourceLocation)
    #expect(geofence.externalId != nil, sourceLocation: sourceLocation)
    #expect(geofence.metadata != nil, sourceLocation: sourceLocation)
}

func expectChainsOk(_ chains: [RadarChain]?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(chains != nil, sourceLocation: sourceLocation)
    for chain in chains ?? [] {
        expectChainOk(chain, sourceLocation: sourceLocation)
    }
}

func expectChainOk(_ chain: RadarChain?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let chain else {
        Issue.record("chain is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(chain.externalId != nil, sourceLocation: sourceLocation)
    #expect(chain.metadata != nil, sourceLocation: sourceLocation)
}

func expectPlacesOk(_ places: [RadarPlace]?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(places != nil, sourceLocation: sourceLocation)
    for place in places ?? [] {
        expectPlaceOk(place, sourceLocation: sourceLocation)
    }
}

func expectPlaceOk(_ place: RadarPlace?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let place else {
        Issue.record("place is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(place.categories.count != 0, sourceLocation: sourceLocation)
    if let chain = place.chain {
        expectChainOk(chain, sourceLocation: sourceLocation)
    }
}

// A region's ID, name, code, and type are non-optional, so only its presence needs checking.
func expectRegionOk(_ region: RadarRegion?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(region != nil, sourceLocation: sourceLocation)
}

func expectSegmentsOk(_ segments: [RadarSegment]?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(segments != nil, sourceLocation: sourceLocation)
    for segment in segments ?? [] {
        expectSegmentOk(segment, sourceLocation: sourceLocation)
    }
}

// A segment's description and external ID are non-optional, so only its presence needs checking.
func expectSegmentOk(_ segment: RadarSegment?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(segment != nil, sourceLocation: sourceLocation)
}

func expectTripOk(_ trip: RadarTrip?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let trip else {
        Issue.record("trip is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(trip.externalId != nil, sourceLocation: sourceLocation)
    #expect(trip.metadata != nil, sourceLocation: sourceLocation)
    #expect(trip.destinationGeofenceTag != nil, sourceLocation: sourceLocation)
    #expect(trip.destinationGeofenceExternalId != nil, sourceLocation: sourceLocation)
    #expect(trip.destinationLocation != nil, sourceLocation: sourceLocation)
    #expect(trip.etaDistance != 0, sourceLocation: sourceLocation)
    #expect(trip.etaDuration != 0, sourceLocation: sourceLocation)
    #expect(trip.status == .started, sourceLocation: sourceLocation)
}

func expectUserOk(_ user: RadarUser?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let user else {
        Issue.record("user is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(user.userId != nil, sourceLocation: sourceLocation)
    #expect(user.deviceId != nil, sourceLocation: sourceLocation)
    #expect(user.__description != nil, sourceLocation: sourceLocation)
    #expect(user.metadata != nil, sourceLocation: sourceLocation)
    expectGeofencesOk(user.geofences, sourceLocation: sourceLocation)
    expectPlaceOk(user.place, sourceLocation: sourceLocation)
    expectRegionOk(user.country, sourceLocation: sourceLocation)
    expectRegionOk(user.state, sourceLocation: sourceLocation)
    expectRegionOk(user.dma, sourceLocation: sourceLocation)
    expectRegionOk(user.postalCode, sourceLocation: sourceLocation)
    expectChainsOk(user.nearbyPlaceChains, sourceLocation: sourceLocation)
    expectSegmentsOk(user.segments, sourceLocation: sourceLocation)
    expectChainsOk(user.topChains, sourceLocation: sourceLocation)
    #expect(user.source != .unknown, sourceLocation: sourceLocation)
    expectTripOk(user.trip, sourceLocation: sourceLocation)
}

func expectEventsOk(_ events: [RadarEvent]?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(events != nil, sourceLocation: sourceLocation)
    for event in events ?? [] {
        expectEventOk(event, sourceLocation: sourceLocation)
    }
}

func expectEventOk(_ event: RadarEvent?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let event else {
        Issue.record("event is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(event.type != .unknown, sourceLocation: sourceLocation)
    #expect(event.confidence != .none, sourceLocation: sourceLocation)
    switch event.type {
    case .userEnteredGeofence:
        expectGeofenceOk(event.geofence, sourceLocation: sourceLocation)
    case .userExitedGeofence:
        expectGeofenceOk(event.geofence, sourceLocation: sourceLocation)
        #expect(event.duration != 0, sourceLocation: sourceLocation)
    case .userEnteredPlace, .userNearbyPlaceChain:
        expectPlaceOk(event.place, sourceLocation: sourceLocation)
    case .userExitedPlace:
        expectPlaceOk(event.place, sourceLocation: sourceLocation)
        #expect(event.duration != 0, sourceLocation: sourceLocation)
    case .userEnteredRegionCountry, .userExitedRegionCountry,
        .userEnteredRegionState, .userExitedRegionState,
        .userEnteredRegionDMA, .userExitedRegionDMA:
        expectRegionOk(event.region, sourceLocation: sourceLocation)
    default:
        break
    }
}

func expectAddressesOk(_ addresses: [RadarAddress]?, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(addresses != nil, sourceLocation: sourceLocation)
    for address in addresses ?? [] {
        expectAddressOk(address, sourceLocation: sourceLocation)
    }
}

func expectAddressOk(_ address: RadarAddress?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let address else {
        Issue.record("address is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(address.coordinate.latitude != 0, sourceLocation: sourceLocation)
    #expect(address.coordinate.longitude != 0, sourceLocation: sourceLocation)
    #expect(address.formattedAddress != nil, sourceLocation: sourceLocation)
    #expect(address.country != nil, sourceLocation: sourceLocation)
    #expect(address.countryCode != nil, sourceLocation: sourceLocation)
    #expect(address.countryFlag != nil, sourceLocation: sourceLocation)
    #expect(address.state != nil, sourceLocation: sourceLocation)
    #expect(address.stateCode != nil, sourceLocation: sourceLocation)
    #expect(address.postalCode != nil, sourceLocation: sourceLocation)
    #expect(address.city != nil, sourceLocation: sourceLocation)
    #expect(address.borough != nil, sourceLocation: sourceLocation)
    #expect(address.county != nil, sourceLocation: sourceLocation)
    #expect(address.neighborhood != nil, sourceLocation: sourceLocation)
    #expect(address.number != nil, sourceLocation: sourceLocation)
    #expect(address.confidence != .none, sourceLocation: sourceLocation)
}

func expectContextOk(_ context: RadarContext?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let context else {
        Issue.record("context is nil", sourceLocation: sourceLocation)
        return
    }
    expectGeofencesOk(context.geofences, sourceLocation: sourceLocation)
    expectPlaceOk(context.place, sourceLocation: sourceLocation)
    expectRegionOk(context.country, sourceLocation: sourceLocation)
    expectRegionOk(context.state, sourceLocation: sourceLocation)
    expectRegionOk(context.dma, sourceLocation: sourceLocation)
    expectRegionOk(context.postalCode, sourceLocation: sourceLocation)
}

func expectRouteOk(_ route: RadarRoute?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let route else {
        Issue.record("route is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(route.distance.value != 0, sourceLocation: sourceLocation)
    #expect(route.duration.value != 0, sourceLocation: sourceLocation)
}

func expectRoutesOk(_ routes: RadarRoutes?, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let routes else {
        Issue.record("routes is nil", sourceLocation: sourceLocation)
        return
    }
    #expect(routes.geodesic?.text != nil, sourceLocation: sourceLocation)
    #expect(routes.geodesic?.value != 0, sourceLocation: sourceLocation)
    expectRouteOk(routes.foot, sourceLocation: sourceLocation)
    expectRouteOk(routes.bike, sourceLocation: sourceLocation)
    expectRouteOk(routes.car, sourceLocation: sourceLocation)
}
