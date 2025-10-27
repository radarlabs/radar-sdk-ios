//
//  AppDelegate.swift
//  Example
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import UIKit
import UserNotifications
import RadarSDK
import SwiftUI


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIWindowSceneDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, RadarDelegate, RadarVerifiedDelegate {

    let locationManager = CLLocationManager()
    var window: UIWindow? // required for UIWindowSceneDelegate
    
    var scrollView: UIScrollView?
    var demoFunctions = Array<() -> Void>()
    
    var useSwiftUI = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in }
        UNUserNotificationCenter.current().delegate = self
        
        locationManager.delegate = self
        self.requestLocationPermissions()
        
        // Replace with a valid test publishable key
        let radarInitializeOptions = RadarInitializeOptions()
        
        // Uncomment to enable automatic setup for notification conversions or deep linking
        //radarInitializeOptions.autoLogNotificationConversions = true
        //radarInitializeOptions.autoHandleNotificationDeepLinks = true
        Radar.initialize(publishableKey: "prj_test_pk_0000000000000000000000000000000000000000", options: radarInitializeOptions)
        Radar.setUserId("testUserId")
        Radar.setDelegate(self)
        Radar.setVerifiedDelegate(self)
        
        return true
    }

    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle opening via standard URL               
        return true
    }
    
    func demoButton(text: String, function: @escaping () -> Void) {
        guard let scrollView = self.scrollView else { return }
        
        let buttonHeight = 30
        scrollView.contentSize.height += CGFloat(buttonHeight)
        
        let buttonFrame = CGRect(x: 0, y: demoFunctions.count * buttonHeight, width: Int(scrollView.frame.width), height: buttonHeight)
        let button = UIButton(frame: buttonFrame, primaryAction:UIAction(handler:{ _ in
            function()
        }))
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        button.setTitle(text, for: .normal)
        
        demoFunctions.append(function)
        
        scrollView.addSubview(button)
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        
        window.backgroundColor = .white

        if (useSwiftUI) {
            let controller = UIHostingController(rootView: MainView())
            controller.view.frame = UIScreen.main.bounds
            window.addSubview(controller.view)
        } else {
            scrollView = UIScrollView(frame: CGRect(x: 0, y: 100, width: window.frame.size.width, height: window.frame.size.height))
            scrollView!.contentSize.height = 0
            scrollView!.contentSize.width = window.frame.size.width
            
            window.addSubview(scrollView!)
        }
        
        window.makeKeyAndVisible()
        
        self.window = window
        
        if UIApplication.shared.applicationState != .background {
            Radar.getLocation { (status, location, stopped) in
                print("Location: status = \(Radar.stringForStatus(status)); location = \(String(describing: location))")
            }

            Radar.trackOnce { (status, location, events, user) in
                print("Track once: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
            }
        }
        
        demoButton(text: "iam") {
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

        demoButton(text: "request motion activity permission") {
            Radar.requestMotionActivityPermission()
        }
        
        demoButton(text: "trackOnce") {
            Radar.trackOnce()
        }


        demoButton(text: "startTracking") {
            let options = RadarTrackingOptions.presetContinuous
            Radar.startTracking(trackingOptions: options)
            
            
        }

        demoButton(text: "getContext") {
            Radar.getContext { (status, location, context) in
                print("Context: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); context?.geofences = \(String(describing: context?.geofences)); context?.place = \(String(describing: context?.place)); context?.country = \(String(describing: context?.country))")
            }
        }
        
        demoButton(text: "startTrackingVerified") {
            Radar.startTrackingVerified(interval: 60, beacons: false)
        }
        
        demoButton(text: "stopTrackingVerified") {
            Radar.stopTrackingVerified()
        }
        
        demoButton(text: "getVerifiedLocationToken") {
            Radar.getVerifiedLocationToken() { (status, token) in
                print("getVerifiedLocationToken: status = \(status); token = \(token?.dictionaryValue())")
            }
        }

        demoButton(text: "trackVerified") {
            Radar.trackVerified() { (status, token) in
                print("TrackVerified: status = \(status); token = \(token?.dictionaryValue())")
            }
        }
        
        demoButton(text: "searchPlaces") {
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

        
        demoButton(text: "searchGeofences") {
            Radar.searchGeofences() { (status, location, geofences) in
                print("Search geofences: status = \(Radar.stringForStatus(status)); geofences = \(String(describing: geofences))")
            }
        }

        demoButton(text: "geocode") {
            Radar.geocode(address: "20 jay st brooklyn") { (status, addresses) in
                print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
            }
            
            Radar.geocode(address: "20 jay st brooklyn", layers: ["place", "locality"], countries: ["US", "CA"]) { (status, addresses) in
                print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
            }
        }

        demoButton(text: "reverseGeocode") {
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
        
        demoButton(text: "ipGeocode") {
            Radar.ipGeocode { (status, address, proxy) in
                print("IP geocode: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city)); proxy = \(proxy); full address: \(String(describing: address?.dictionaryValue()))")
            }
        }

        demoButton(text: "validateAddress") {
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
        
        demoButton(text: "autocomplete") {
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

        demoButton(text: "getDistance") {
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

        demoButton(text: "startTrip") {
            let tripOptions = RadarTripOptions(externalId: "300", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123")
            tripOptions.mode = .car
            tripOptions.approachingThreshold = 9
            Radar.startTrip(options: tripOptions)
        }

        demoButton(text: "startTrip with start tracking false") {
            let tripOptions = RadarTripOptions(externalId: "301", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil, startTracking: false)
            tripOptions.mode = .car
            tripOptions.approachingThreshold = 9
            Radar.startTrip(options: tripOptions)
        }

        demoButton(text: "startTrip with tracking options") {
            let tripOptions = RadarTripOptions(externalId: "301", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil, startTracking: false)
            tripOptions.mode = .car
            tripOptions.approachingThreshold = 9
            let trackingOptions = RadarTrackingOptions.presetContinuous
            Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
        }

        demoButton(text: "startTrip with tracking options and startTrackingAfter") {
            let tripOptions = RadarTripOptions(externalId: "303", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123", scheduledArrivalAt: nil)
            tripOptions.startTracking = false
            tripOptions.mode = .car
            tripOptions.approachingThreshold = 9
            let trackingOptions = RadarTrackingOptions.presetContinuous
            // startTrackingAfter 3 minutes from now
            trackingOptions.startTrackingAfter = Date().addingTimeInterval(180)
            Radar.startTrip(options: tripOptions, trackingOptions: trackingOptions)
        }

        demoButton(text: "completeTrip") {
            Radar.completeTrip()
        }

        demoButton(text: "mockTracking") {
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

        demoButton(text: "getMatrix") {
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

        demoButton(text: "logConversion") {
            Radar.logConversion(name: "conversion_event", metadata: ["data": "test"]) { (status, event) in
                if let conversionEvent = event, conversionEvent.type == .conversion {
                    print("Conversion name: \(conversionEvent.conversionName!)")
                }
                
                print("Log Conversion: status = \(Radar.stringForStatus(status)); event = \(String(describing: event))")
            }
        }
        
        demoButton(text: "Run all") {
            for function in self.demoFunctions.dropLast() {
                function()
            }
        }
    }

    func requestLocationPermissions() {
        var status: CLAuthorizationStatus = .notDetermined
        if #available(iOS 14.0, *) {
            // On iOS 14.0 and later, use the authorizationStatus instance property.
            status = self.locationManager.authorizationStatus
        } else {
            // Before iOS 14.0, use the authorizationStatus class method.
            status = CLLocationManager.authorizationStatus()
        }

        if #available(iOS 13.4, *) {
            // On iOS 13.4 and later, prompt for foreground first. If granted, prompt for background. The OS will show the background prompt in-app.
            if status == .notDetermined {
                self.locationManager.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse {
                self.locationManager.requestAlwaysAuthorization()
            }
        } else {
            // Before iOS 13.4, prompt for background first. On iOS 13, the OS will show a foreground prompt in-app. The OS will show the background prompt outside of the app later, at a time determined by the OS.
            self.locationManager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.requestLocationPermissions()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("will present notification!")
        completionHandler([.list, .banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Uncomment for manual setup for notification conversions and URLs
        // Radar.logConversion(response: response)
        // Radar.openURLFromNotification(response.notification)
        print("Received notification!")
    }

    func notify(_ body: String) {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
//            if granted {
//                let content = UNMutableNotificationContent()
//                content.body = body
//                content.sound = UNNotificationSound.default
//                content.categoryIdentifier = "example"
//
//                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
//                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
//            }
//        }
    }

    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
        for event in events {
            notify(Utils.stringForRadarEvent(event))
        }
    }

    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        let body = "\(user.stopped ? "Stopped at" : "Moved to") location (\(location.coordinate.latitude), \(location.coordinate.longitude)) with accuracy \(location.horizontalAccuracy) meters"
        self.notify(body)
    }

    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        let body = "\(stopped ? "Client stopped at" : "Client moved to") location (\(location.coordinate.latitude), \(location.coordinate.longitude)) with accuracy \(location.horizontalAccuracy) meters and source \(Utils.stringForRadarLocationSource(source))"
        self.notify(body)
    }

    func didFail(status: RadarStatus) {
        self.notify(Radar.stringForStatus(status))
    }

    func didLog(message: String) {
        self.notify(message)
    }

    func didUpdateToken(_ token: RadarVerifiedLocationToken) {
        
    }
    
}
