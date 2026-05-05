//
//  SearchPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct SearchPanel: View {
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
                ) { (status, location, places) in
                    print("Search places: status = \(Radar.stringForStatus(status)); places = \(String(describing: places))")
                }
            }
            ActionButton("searchGeofences") {
                Radar.searchGeofences() { (status, location, geofences) in
                    print("Search geofences: status = \(Radar.stringForStatus(status)); geofences = \(String(describing: geofences))")
                }
            }
            ActionButton("geocode") {
                Radar.geocode(address: "20 jay st brooklyn") { (status, addresses) in
                    print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
                }
                Radar.geocode(address: "20 jay st brooklyn", layers: ["place", "locality"], countries: ["US", "CA"]) { (status, addresses) in
                    print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
                }
            }
            ActionButton("reverseGeocode") {
                Radar.reverseGeocode { (status, addresses) in
                    print("Reverse geocode: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
                }
                Radar.reverseGeocode(layers: ["locality", "state"]) { (status, addresses) in
                    print("Reverse geocode: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
                }
                Radar.reverseGeocode(location: CLLocation(latitude: 40.70390, longitude: -73.98670)) { (status, addresses) in
                    print("Reverse geocode: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
                }
                Radar.reverseGeocode(location: CLLocation(latitude: 40.70390, longitude: -73.98670), layers: ["locality", "state"]) { (status, addresses) in
                    print("Reverse geocode: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
                }
            }
            ActionButton("ipGeocode") {
                Radar.ipGeocode { (status, address, proxy) in
                    print("IP geocode: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city)); proxy = \(proxy); full address: \(String(describing: address?.dictionaryValue()))")
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
                    print("Validate address with street + number: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city)); verificationStatus = \(verificationStatus)")
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
                    print("Validate address with address label: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city)); verificationStatus = \(verificationStatus)")
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
                    print("Autocomplete: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
                    if let address = addresses?.first {
                        Radar.validateAddress(address: address) { (status, address, verificationStatus) in
                            print("Validate address: status = \(Radar.stringForStatus(status)); address = \(String(describing: address)); verificationStatus = \(Radar.stringForVerificationStatus(verificationStatus))")
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
                    print("Autocomplete: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
                    if let address = addresses?.first {
                        Radar.validateAddress(address: address) { (status, address, verificationStatus) in
                            print("Validate address: status = \(Radar.stringForStatus(status)); address = \(String(describing: address)); verificationStatus = \(Radar.stringForVerificationStatus(verificationStatus))")
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
                    print("Autocomplete: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
                }
            }
            ActionButton("getDistance") {
                let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
                let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)
                Radar.getDistance(
                    origin: origin,
                    destination: destination,
                    modes: [.foot, .car],
                    units: .imperial
                ) { (status, routes) in
                    print("Distance: status = \(Radar.stringForStatus(status)); routes.car.distance.value = \(String(describing: routes?.car?.distance.value)); routes.car.distance.text = \(String(describing: routes?.car?.distance.text)); routes.car.duration.value = \(String(describing: routes?.car?.duration.value)); routes.car.duration.text = \(String(describing: routes?.car?.duration.text))")
                }
            }
            ActionButton("getMatrix") {
                let origins = [
                    CLLocation(latitude: 40.78382, longitude: -73.97536),
                    CLLocation(latitude: 40.70390, longitude: -73.98670)
                ]
                let destinations = [
                    CLLocation(latitude: 40.64189, longitude: -73.78779),
                    CLLocation(latitude: 35.99801, longitude: -78.94294)
                ]
                Radar.getMatrix(origins: origins, destinations: destinations, mode: .car, units: .imperial) { (status, matrix) in
                    print("Matrix: status = \(Radar.stringForStatus(status)); matrix[0][0].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 0, destinationIndex: 0)?.duration.text)); matrix[0][1].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 0, destinationIndex: 1)?.duration.text)); matrix[1][0].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 1, destinationIndex: 0)?.duration.text)); matrix[1][1].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 1, destinationIndex: 1)?.duration.text))")
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        SearchPanel().padding()
    }
}
