//
//  TestsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct TestsView: View {
    var body: some View {
        ScrollView {
            StyledButton("trackOnce") {
                Radar.trackOnce()
            }
            
            StyledButton("startTracking") {
                Radar.startTracking(trackingOptions: .presetResponsive)
            }
            
            StyledButton("stopTracking") {
                Radar.stopTracking()
            }
            
            StyledButton("test notification") {
                let content = UNMutableNotificationContent()
                content.body = "Test"
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = "example"
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
            }
            
            StyledButton("iam") {
                Radar.showInAppMessage(RadarInAppMessage.fromDictionary([
                    "title": [
                        "text": "This is the title",
                        "color": "#ff0000"
                    ],
                    "body": [
                        "text": "This is a demo message.",
                        "color": "#00ff00"
                    ],
                    "button": [
                        "text": "Buy it",
                        "color": "#0000ff",
                        "backgroundColor": "#EB0083",
                    ],
                    "image": [
                        "url": "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg",
                        "name": "image.jpeg"
                    ],
                    "metadata": [
                        "campainId": "1234"
                    ]
                ])!)
            }
            
            StyledButton("request motion activity permission") {
                Radar.requestMotionActivityPermission()
            }
            
            StyledButton("trackOnce") {
                Radar.trackOnce()
            }
            
            
            StyledButton("startTracking") {
                let options = RadarTrackingOptions.presetContinuous
                Radar.startTracking(trackingOptions: options)
                
                
            }
            
            StyledButton("getContext") {
                Radar.getContext { (status, location, context) in
                    print("Context: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); context?.geofences = \(String(describing: context?.geofences)); context?.place = \(String(describing: context?.place)); context?.country = \(String(describing: context?.country))")
                }
            }
            
            StyledButton("startTrackingVerified") {
                Radar.startTrackingVerified(interval: 60, beacons: false)
            }
            
            StyledButton("stopTrackingVerified") {
                Radar.stopTrackingVerified()
            }
            
            StyledButton("getVerifiedLocationToken") {
                Radar.getVerifiedLocationToken() { (status, token) in
                    print("getVerifiedLocationToken: status = \(status); token = \(String(describing: token?.dictionaryValue()))")
                }
            }
            
            StyledButton("trackVerified") {
                Radar.trackVerified() { (status, token) in
                    print("TrackVerified: status = \(status); token = \(String(describing: token?.dictionaryValue()))")
                }
            }
            
            StyledButton("searchPlaces") {
                // In the Radar dashboard settings
                // (https://radar.com/dashboard/settings), add this to the chain
                // metadata: {"mcdonalds":{"orderActive":"true"}}.
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
            
            
            StyledButton("searchGeofences") {
                Radar.searchGeofences() { (status, location, geofences) in
                    print("Search geofences: status = \(Radar.stringForStatus(status)); geofences = \(String(describing: geofences))")
                }
            }
            
            StyledButton("geocode") {
                Radar.geocode(address: "20 jay st brooklyn") { (status, addresses) in
                    print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
                }
                
                Radar.geocode(address: "20 jay st brooklyn", layers: ["place", "locality"], countries: ["US", "CA"]) { (status, addresses) in
                    print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
                }
            }
            
            StyledButton("reverseGeocode") {
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
            
            StyledButton("ipGeocode") {
                Radar.ipGeocode { (status, address, proxy) in
                    print("IP geocode: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city)); proxy = \(proxy); full address: \(String(describing: address?.dictionaryValue()))")
                }
            }
            
            StyledButton("validateAddress") {
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
            
            StyledButton("autocomplete") {
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
                    mailable:true
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
            
            StyledButton("getDistance") {
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
            
            StyledButton("startTrip") {
                let tripOptions = RadarTripOptions(externalId: "300", destinationGeofenceTag: "a", destinationGeofenceExternalId: "a")
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                Radar.startTrip(options: tripOptions)
            }
            
            StyledButton("startTrip with start tracking false") {
                let tripOptions = RadarTripOptions(externalId: "301", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil, startTracking: false)
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                Radar.startTrip(options: tripOptions)
            }
            
            StyledButton("startTrip with tracking options") {
                let tripOptions = RadarTripOptions(externalId: "301", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil, startTracking: false)
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                let trackingOptions = RadarTrackingOptions.presetContinuous
                Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
            }
            
            StyledButton("startTrip with tracking options and startTrackingAfter") {
                let tripOptions = RadarTripOptions(externalId: "303", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil)
                tripOptions.startTracking = false
                tripOptions.mode = .car
                tripOptions.approachingThreshold = 9
                let trackingOptions = RadarTrackingOptions.presetContinuous
                // startTrackingAfter 3 minutes from now
                trackingOptions.startTrackingAfter = Date().addingTimeInterval(180)
                Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
            }
            
            StyledButton("completeTrip") {
                Radar.completeTrip()
            }
            
            StyledButton("mockTracking") {
                let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
                let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)
                var i = 0
                Radar.mockTracking(
                    origin: origin,
                    destination: destination,
                    mode: .car,
                    steps: 3,
                    interval: 3
                ) { (status, location, events, user) in
                    print("Mock track: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
                    
                    if (i == 2) {
                        Radar.completeTrip()
                    }
                    
                    i += 1
                }
            }
            
            StyledButton("getMatrix") {
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
            
            StyledButton("logConversion") {
                Radar.logConversion(name: "conversion_event", metadata: ["data": "test"]) { (status, event) in
                    if let conversionEvent = event, conversionEvent.type == .conversion {
                        print("Conversion name: \(conversionEvent.conversionName!)")
                    }
                    
                    print("Log Conversion: status = \(Radar.stringForStatus(status)); event = \(String(describing: event))")
                }
            }
        }
    }
}

#Preview {
    TestsView()
}
