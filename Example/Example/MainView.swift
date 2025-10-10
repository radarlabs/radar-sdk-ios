//
//  MainView.swift
//  Example
//
//  Created by ShiCheng Lu on 9/5/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapKit
import RadarSDK

struct MainView: View {
    
    let radarDelegate = MyRadarDelegate()
    
    init() {
        Radar.setDelegate(radarDelegate)
    }
    
    enum TabIdentifier {
        case Map
        case Debug
        case Custom
        case Tests
    }
    
    @State var monitoringRegions = [CLCircularRegion]();
    @State var pendingNotifications = [UNNotificationRequest]();
    @State var nearbyGeofences = [CLCircularRegion]()
    @State private var selectedTab: TabIdentifier = .Tests;
    
    var regionListFont = {
        if #available(iOS 15.0, *) {
            Font.system(size: 12).monospaced()
        } else {
            Font.system(size: 12)
        }
    }()
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    func getMonitoredRegions() {
        monitoringRegions = Array(CLLocationManager().monitoredRegions) as? [CLCircularRegion] ?? []
    }
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            pendingNotifications = requests
        }
    }
    
    func getNearbyGeofences() {
        var path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        path = path.appendingPathComponent("offlineData.json")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path.path)),
              let json = try? JSONSerialization.jsonObject(with: data),
              let arr = json as? [String: Any],
              let geofencesJSON = arr["geofences"] as? [[String: Any]] else {
            return
        }
        
        nearbyGeofences = geofencesJSON.compactMap { geofence -> CLCircularRegion? in
            guard let geometry = geofence["geometryCenter"] as? [String: Any],
                  let coord = geometry["coordinates"] as? [Double],
                  let radius = geofence["geometryRadius"] as? Double,
                  let id = geofence["_id"] as? String else {
                return nil
            }
            let center = CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
            
            return CLCircularRegion.init(center:center, radius:radius, identifier:id)
        }
    }
    
    @State var content: [(Int, String)] = [(0, "Empty")]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if #available(iOS 17.0, *) {
                Map(initialPosition: .userLocation(fallback: .automatic)) {
                    UserAnnotation()
                    
                    ForEach(nearbyGeofences, id:\.self) {region in
                        let color = Color.green
                        MapCircle(center: region.center, radius: region.radius)
                            .foregroundStyle(color.opacity(0.2))
                            .stroke(color, lineWidth: 2)
                    }

                    ForEach(monitoringRegions, id:\.self) {region in
                        let color = region.identifier.contains("bubble") ? Color.blue : Color.orange
                        MapCircle(center: region.center, radius: region.radius)
                            .foregroundStyle(color.opacity(0.2))
                            .stroke(color, lineWidth: 2)

                    }
                }.tabItem {
                    Text("Map")
                }.tag(TabIdentifier.Map)
            } else {
                // Fallback on earlier versions
                Text("Map unavailable")
                    .tabItem { Text("Map") }
                    .tag(TabIdentifier.Map)
            }
            
            VStack {
                Text("logs/events will go here")
                List(radarDelegate.events, id:\.self) { item in
                    let type = RadarEvent.string(for: item.type) ?? "unknown-type"
                    var description = ""
                    if let geofence = item.geofence {
                        description = geofence.externalId ?? ""
                    }
                    return Text("\(type): \(description)")
                }
                
                List(content, id:\.0) { item in
                    if #available(iOS 15.0, *) {
                        Text(item.1)
                            .frame(height: 5)
                            .listRowSeparator(.hidden)
                    } else {
                        // Fallback on earlier versions
                    }
                }.environment(\.defaultMinListRowHeight, 5)
                .listStyle(PlainListStyle())
                Button("update content") {
                    do {
                        let filename = "offlineData.json"
                        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        let path =  dir.appendingPathComponent(filename).path
                        
                        let data = try Data(contentsOf: URL(fileURLWithPath: path))
                        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                        let prettyPrintedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                        content = Array((String(data: prettyPrintedData!, encoding: .ascii) ?? "").split(separator: "\n").map(\.description).enumerated())
                    } catch {
                        print("-- Failed --")
                    }
                }
                
                Button("Delete file") {
                    do {
                        let filename = "offlineData.json"
                        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        let path =  dir.appendingPathComponent(filename).path
                        
                        try FileManager.default.removeItem(atPath: path)
                    } catch {
                        print("Failed")
                    }
                }
            }.tabItem {
                Text("Debug")
            }.tag(TabIdentifier.Debug)

            VStack {
//                
//                @State var arg = ""
//                
//                TextField("Custom arg", text: $arg)
//                
//                
//                
//                Button("") {
//                    Radar.trackOnce()
//                }
//                
//                
//                
            }.tabItem {
                Text("Custom")
            }.tag(TabIdentifier.Custom)
            
            
            VStack {
                // TODO: make buttons take params for some functions
                @State var output = "Calloutput: "
                
                Text(output)
                
                Button("trackOnce") {
                    Radar.trackOnce() { status, location, events, user in
                        print(status, location, events, user)
                    }
                }
                
                Button("startTracking") {
                    Radar.startTracking(trackingOptions: .presetResponsive)
                }
                
                Button("stopTracking") {
                    Radar.stopTracking()
                }
                
                Button("refresh") {
                    getMonitoredRegions()
                    getPendingNotifications()
                    getNearbyGeofences()
                }
                
                Button("test notification") {
                    let content = UNMutableNotificationContent()
                    content.body = "Test"
                    content.sound = UNNotificationSound.default
                    content.categoryIdentifier = "example"

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
                }
                
                Text("").onReceive(timer) { _ in
                    getMonitoredRegions()
                    getPendingNotifications()
                    getNearbyGeofences()
                }
                
                Button("iam") {
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
                            "campaignId": "1234"
                        ]
                    ])!)
                }

                Button("request motion activity permission") {
                    Radar.requestMotionActivityPermission()
                }
                
                Button("getContext") {
                    Radar.getContext { (status, location, context) in
                        print("Context: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); context?.geofences = \(String(describing: context?.geofences)); context?.place = \(String(describing: context?.place)); context?.country = \(String(describing: context?.country))")
                    }
                }
                
                Button("startTrackingVerified") {
                    Radar.startTrackingVerified(interval: 60, beacons: false)
                }
                
                Button("stopTrackingVerified") {
                    Radar.stopTrackingVerified()
                }
                
                Button("getVerifiedLocationToken") {
                    Radar.getVerifiedLocationToken() { (status, token) in
                        print("getVerifiedLocationToken: status = \(status); token = \(token?.dictionaryValue())")
                    }
                }

                Button("trackVerified") {
                    Radar.trackVerified() { (status, token) in
                        print("TrackVerified: status = \(status); token = \(token?.dictionaryValue())")
                    }
                }
                
                Button("searchPlaces") {
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

                
                Button("searchGeofences") {
                    Radar.searchGeofences() { (status, location, geofences) in
                        print("Search geofences: status = \(Radar.stringForStatus(status)); geofences = \(String(describing: geofences))")
                    }
                }

                Button("geocode") {
                    Radar.geocode(address: "20 jay st brooklyn") { (status, addresses) in
                        print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
                    }
                    
                    Radar.geocode(address: "20 jay st brooklyn", layers: ["place", "locality"], countries: ["US", "CA"]) { (status, addresses) in
                        print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
                    }
                }

                Button("reverseGeocode") {
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
                
                Button("ipGeocode") {
                    Radar.ipGeocode { (status, address, proxy) in
                        print("IP geocode: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city)); proxy = \(proxy); full address: \(String(describing: address?.dictionaryValue()))")
                    }
                }

                Button("validateAddress") {
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
                
                Button("autocomplete") {
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

                Button("getDistance") {
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

                Button("startTrip") {
                    let tripOptions = RadarTripOptions(externalId: "300", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123")
                    tripOptions.mode = .car
                    tripOptions.approachingThreshold = 9
                    Radar.startTrip(options: tripOptions)
                }

                Button("startTrip with start tracking false") {
                    let tripOptions = RadarTripOptions(externalId: "301", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil, startTracking: false)
                    tripOptions.mode = .car
                    tripOptions.approachingThreshold = 9
                    Radar.startTrip(options: tripOptions)
                }

                Button("startTrip with tracking options") {
                    let tripOptions = RadarTripOptions(externalId: "301", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil, startTracking: false)
                    tripOptions.mode = .car
                    tripOptions.approachingThreshold = 9
                    let trackingOptions = RadarTrackingOptions.presetContinuous
                    Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
                }

                Button("startTrip with tracking options and startTrackingAfter") {
                    let tripOptions = RadarTripOptions(externalId: "303", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil)
                    tripOptions.startTracking = false
                    tripOptions.mode = .car
                    tripOptions.approachingThreshold = 9
                    let trackingOptions = RadarTrackingOptions.presetContinuous
                    // startTrackingAfter 3 minutes from now
                    trackingOptions.startTrackingAfter = Date().addingTimeInterval(180)
                    Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
                }

                Button("completeTrip") {
                    Radar.completeTrip()
                }

                Button("mockTracking") {
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

                Button("getMatrix") {
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

                Button("logConversion") {
                    Radar.logConversion(name: "conversion_event", metadata: ["data": "test"]) { (status, event) in
                        if let conversionEvent = event, conversionEvent.type == .conversion {
                            print("Conversion name: \(conversionEvent.conversionName!)")
                        }
                        
                        print("Log Conversion: status = \(Radar.stringForStatus(status)); event = \(String(describing: event))")
                    }
                }
            }.tabItem {
                Text("Tests")
            }.tag(TabIdentifier.Tests)
        }
        
        
        
    }
}

#Preview {
    if #available(iOS 15.0, *) {
        MainView()
    } else {
        // Fallback on earlier versions
    }
}
