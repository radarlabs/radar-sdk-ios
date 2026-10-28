//
//  RadarContext.swift
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents the context for a location.
///
/// - SeeAlso: https://radar.com/documentation/api#context
@objc(RadarContext)
@objcMembers
public final class RadarContext: NSObject {
    /// An array of the geofences for the location. May be empty if the location is not in any geofences.
    ///
    /// - SeeAlso: https://radar.com/documentation/geofences
    public let geofences: [RadarGeofence]

    /// The place for the location. May be `nil` if the location is not at a place or if Places is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/places
    public let place: RadarPlace?

    /// The country of the location. May be `nil` if country is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let country: RadarRegion?

    /// The state of the location. May be `nil` if state is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let state: RadarRegion?

    /// The designated market area (DMA) of the location. May be `nil` if DMA is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let dma: RadarRegion?

    /// The postal code of the location. May be `nil` if postal code is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let postalCode: RadarRegion?

    override init() {
        geofences = []
        place = nil
        country = nil
        state = nil
        dma = nil
        postalCode = nil
        super.init()
    }

    // Declared for Objective-C in RadarContext+Internal.h.
    @objc(initWithGeofences:place:country:state:dma:postalCode:)
    init(
        geofences: [RadarGeofence],
        place: RadarPlace?,
        country: RadarRegion?,
        state: RadarRegion?,
        dma: RadarRegion?,
        postalCode: RadarRegion?
    ) {
        self.geofences = geofences
        self.place = place
        self.country = country
        self.state = state
        self.dma = dma
        self.postalCode = postalCode
        super.init()
    }

    // Keeps the Objective-C parser declared in RadarContext+Internal.h working.
    // Geofences, places, and regions are built through `RadarSwift.bridge`, because their parsers
    // are internal Objective-C. The bridge is installed by `Radar.initialize`, which runs before
    // any context request.
    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dict = object as? NSDictionary else {
            return nil
        }

        var geofences: [RadarGeofence] = []
        if let geofencesArray = dict["geofences"] as? NSArray {
            // Like the Objective-C parser, any geofence that fails to parse fails the whole context.
            for geofenceObject in geofencesArray {
                guard let geofenceDict = geofenceObject as? [String: Any],
                    let geofence = RadarSwift.bridge?.createGeofence(dict: geofenceDict)
                else {
                    return nil
                }
                geofences.append(geofence)
            }
        }

        let place = (dict["place"] as? [String: Any]).flatMap { RadarSwift.bridge?.createPlace(dict: $0) }

        func region(_ key: String) -> RadarRegion? {
            RadarRegion(object: dict[key])
        }

        self.init(
            geofences: geofences,
            place: place,
            country: region("country"),
            state: region("state"),
            dma: region("dma"),
            postalCode: region("postalCode")
        )
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        if let geofencesArray = RadarGeofence.array(for: geofences) {
            dict["geofences"] = geofencesArray
        }
        if let place {
            dict["place"] = place.dictionaryValue()
        }
        if let country {
            dict["country"] = country.dictionaryValue()
        }
        if let state {
            dict["state"] = state.dictionaryValue()
        }
        if let dma {
            dict["dma"] = dma.dictionaryValue()
        }
        if let postalCode {
            dict["postalCode"] = postalCode.dictionaryValue()
        }
        return dict
    }
}
