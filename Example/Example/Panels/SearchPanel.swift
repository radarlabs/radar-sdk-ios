//
//  SearchPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

struct SearchPanel: View {
    @EnvironmentObject var logStream: LogStream

    var body: some View {
        TogglePanel("Search & Geocoding", initiallyExpanded: false) {
            ActionButton("searchPlaces") {
                // In the Radar dashboard settings (https://radar.com/dashboard/settings),
                // add this to the chain metadata: {"mcdonalds":{"orderActive":"true"}}.
                Radar.searchPlaces(
                    radius: 1000,
                    chains: ["mcdonalds"],
                    chainMetadata: ["orderActive": "true"],
                    categories: nil,
                    groups: nil,
                    countryCodes: ["US"],
                    limit: 10
                ) { (status, _, places) in
                    logStream.write(
                        status,
                        summary: "searchPlaces: \(Radar.stringForStatus(status))",
                        detail: "places = \(String(describing: places))"
                    )
                }
            }
            ActionButton("searchGeofences") {
                Radar.searchGeofences { (status, _, geofences) in
                    logStream.write(
                        status,
                        summary: "searchGeofences: \(Radar.stringForStatus(status))",
                        detail: "geofences = \(String(describing: geofences))"
                    )
                }
            }
            ActionButton("geocode") {
                Radar.geocode(address: "20 jay st brooklyn") { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "geocode: \(Radar.stringForStatus(status))",
                        detail: "coordinate = \(String(describing: addresses?.first?.coordinate))"
                    )
                }
                Radar.geocode(
                    address: "20 jay st brooklyn",
                    layers: ["place", "locality"],
                    countries: ["US", "CA"]
                ) { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "geocode (layered): \(Radar.stringForStatus(status))",
                        detail: "coordinate = \(String(describing: addresses?.first?.coordinate))"
                    )
                }
            }
            ActionButton("reverseGeocode") {
                Radar.reverseGeocode { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "reverseGeocode: \(Radar.stringForStatus(status))",
                        detail: "formattedAddress = \(String(describing: addresses?.first?.formattedAddress))"
                    )
                }
                Radar.reverseGeocode(layers: ["locality", "state"]) { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "reverseGeocode (layered): \(Radar.stringForStatus(status))",
                        detail: "formattedAddress = \(String(describing: addresses?.first?.formattedAddress))"
                    )
                }
                Radar.reverseGeocode(
                    location: CLLocation(latitude: 40.70390, longitude: -73.98670)
                ) { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "reverseGeocode (location): \(Radar.stringForStatus(status))",
                        detail: "formattedAddress = \(String(describing: addresses?.first?.formattedAddress))"
                    )
                }
                Radar.reverseGeocode(
                    location: CLLocation(latitude: 40.70390, longitude: -73.98670),
                    layers: ["locality", "state"]
                ) { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "reverseGeocode (location, layered): \(Radar.stringForStatus(status))",
                        detail: "formattedAddress = \(String(describing: addresses?.first?.formattedAddress))"
                    )
                }
            }
            ActionButton("ipGeocode") {
                Radar.ipGeocode { (status, address, proxy) in
                    let detail = """
                        country: \(String(describing: address?.countryCode))
                        city: \(String(describing: address?.city))
                        proxy: \(proxy)
                        full: \(String(describing: address?.dictionaryValue()))
                        """
                    logStream.write(
                        status,
                        summary: "ipGeocode: \(Radar.stringForStatus(status))",
                        detail: detail
                    )
                }
            }
            ActionButton("validateAddress") {
                let address: RadarAddress = RadarAddress(from: [
                    "latitude": 0,
                    "longitude": 0,
                    "city": "New York",
                    "stateCode": "NY",
                    "postalCode": "10003",
                    "countryCode": "US",
                    "street": "Broadway",
                    "number": "841",
                ])!
                Radar.validateAddress(address: address) { (status, address, verificationStatus) in
                    let detail = """
                        country: \(String(describing: address?.countryCode))
                        city: \(String(describing: address?.city))
                        verificationStatus: \(Radar.stringForVerificationStatus(verificationStatus))
                        """
                    logStream.write(
                        status,
                        summary: "validateAddress (street + number): \(Radar.stringForStatus(status))",
                        detail: detail
                    )
                }
                let addressLabel: RadarAddress = RadarAddress(from: [
                    "latitude": 0,
                    "longitude": 0,
                    "city": "New York",
                    "stateCode": "NY",
                    "postalCode": "10003",
                    "countryCode": "US",
                    "addressLabel": "Broadway 841",
                ])!
                Radar.validateAddress(address: addressLabel) { (status, address, verificationStatus) in
                    let detail = """
                        country: \(String(describing: address?.countryCode))
                        city: \(String(describing: address?.city))
                        verificationStatus: \(Radar.stringForVerificationStatus(verificationStatus))
                        """
                    logStream.write(
                        status,
                        summary: "validateAddress (label): \(Radar.stringForStatus(status))",
                        detail: detail
                    )
                }
            }
            ActionButton("autocomplete") {
                let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
                Radar.autocomplete(
                    query: "brooklyn",
                    near: origin,
                    layers: ["locality"],
                    limit: 10,
                    country: "US"
                ) { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "autocomplete: \(Radar.stringForStatus(status))",
                        detail: "formattedAddress = \(String(describing: addresses?.first?.formattedAddress))"
                    )
                    if let address = addresses?.first {
                        Radar.validateAddress(address: address) { (status, address, verificationStatus) in
                            logStream.write(
                                status,
                                summary: "validateAddress (from autocomplete): \(Radar.stringForStatus(status))",
                                detail: "address = \(String(describing: address)); verificationStatus = \(Radar.stringForVerificationStatus(verificationStatus))"
                            )
                        }
                    }
                }
                Radar.autocomplete(
                    query: "brooklyn",
                    near: origin,
                    layers: ["locality"],
                    limit: 10,
                    country: "US",
                    mailable: true
                ) { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "autocomplete (mailable): \(Radar.stringForStatus(status))",
                        detail: "formattedAddress = \(String(describing: addresses?.first?.formattedAddress))"
                    )
                    if let address = addresses?.first {
                        Radar.validateAddress(address: address) { (status, address, verificationStatus) in
                            logStream.write(
                                status,
                                summary: "validateAddress (from autocomplete): \(Radar.stringForStatus(status))",
                                detail: "address = \(String(describing: address)); verificationStatus = \(Radar.stringForVerificationStatus(verificationStatus))"
                            )
                        }
                    }
                }
                Radar.autocomplete(
                    query: "brooklyn",
                    near: origin,
                    layers: ["locality"],
                    limit: 10,
                    country: "US"
                ) { (status, addresses) in
                    logStream.write(
                        status,
                        summary: "autocomplete (no validate): \(Radar.stringForStatus(status))",
                        detail: "formattedAddress = \(String(describing: addresses?.first?.formattedAddress))"
                    )
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        SearchPanel().padding()
    }
    .environmentObject(LogStream())
}
