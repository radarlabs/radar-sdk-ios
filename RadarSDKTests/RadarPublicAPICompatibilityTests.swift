//
//  RadarPublicAPICompatibilityTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

/// Swift call shapes that compiled against the handwritten Objective-C headers these classes used
/// to have. The explicit type annotations are the point: if a Swift implementation changes a
/// public name, type, or nullability, this file stops compiling.
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

    @Test func chainArrayUsesForLabel() {
        let dictionaries: [[String: Any]]? = RadarChain.array(for: nil)
        #expect(dictionaries == nil)
    }

    @Test func tripOptionsExternalIdIsNonOptionalString() {
        let options = RadarTripOptions(
            externalId: "trip-id",
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil
        )
        let externalId: String = options.externalId
        #expect(externalId.count == 7)
    }

    @Test func operatingHoursKeepsTypedDictionary() {
        let operatingHours = RadarOperatingHours(dictionary: ["mon": [["09:00", "17:00"]]])
        let hours: [String: [[String]]] = operatingHours.hours
        #expect(hours["mon"] == [["09:00", "17:00"]])
    }

    @Test func revealRiskTokenKeepsPublicPropertyNames() throws {
        let json: [String: Any] = [
            "_id": "risk-token",
            "expiresIn": 3600,
            "risk": ["level": "low", "reasons": []],
            "network": [
                "ipAddress": [
                    "latitude": 40.7,
                    "longitude": -74.0,
                    "stateAllowed": true,
                    "countryAllowed": true,
                    "geometry": ["type": "Point", "coordinates": [-74.0, 40.7]],
                ],
                "privacy": [
                    "hosting": true,
                    "proxy": true,
                    "relay": true,
                    "tor": true,
                    "vpn": true,
                    "residentialProxy": true,
                ],
            ],
            "device": [:],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let token = try #require(RadarRevealRiskToken.fromData(data))

        let expiresIn: NSNumber? = token.expiresIn
        #expect(expiresIn == 3600)

        let ipAddress = try #require(token.network.ipAddress)
        let latitude: NSNumber? = ipAddress.latitude
        let longitude: NSNumber? = ipAddress.longitude
        let stateAllowed: Bool = ipAddress.stateAllowed
        let countryAllowed: Bool = ipAddress.countryAllowed
        let coordinates: [NSNumber]? = ipAddress.geometry?.coordinates
        #expect(latitude == 40.7)
        #expect(longitude == -74.0)
        #expect(stateAllowed && countryAllowed)
        #expect(coordinates == [-74.0, 40.7])

        let privacy = try #require(token.network.privacy)
        let flags: [Bool] = [
            privacy.hosting, privacy.proxy, privacy.relay, privacy.tor, privacy.vpn, privacy.residentialProxy,
        ]
        #expect(flags.allSatisfy { $0 })
    }
}
