//
//  AppDelegate.swift
//  Example
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import UIKit
import UserNotifications
import RadarSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, RadarDelegate {

    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in }
        UNUserNotificationCenter.current().delegate = self

        locationManager.requestAlwaysAuthorization()

        Radar.initialize(publishableKey: "org_test_pk_5857c63d9c1565175db8b00750808a66a002acb8")
        Radar.setLogLevel(.debug)
        Radar.setDelegate(self)
        
        /*if UIApplication.shared.applicationState != .background {
            Radar.getLocation { (status, location, stopped) in
                print("Location: status = \(Radar.stringForStatus(status)); location = \(String(describing: location))")
            }
            
            Radar.trackOnce { (status, location, events, user) in
                print("Track once: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
            }
        }

        let options = RadarTrackingOptions.responsive
        options.sync = .all
        options.showBlueBar = true
        Radar.startTracking(trackingOptions: options)
        
        Radar.getContext { (status, location, context) in
            print("Context: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); context?.geofences = \(String(describing: context?.geofences)); context?.place = \(String(describing: context?.place)); context?.country = \(String(describing: context?.country))")
        }

        Radar.searchPlaces(
            radius: 1000,
            chains: ["mcdonalds"],
            categories: nil,
            groups: nil,
            limit: 10
        ) { (status, location, places) in
            print("Search places: status = \(Radar.stringForStatus(status)); places = \(String(describing: places))")
        }

        Radar.searchGeofences(
            radius: 1000,
            tags: ["store"],
            limit: 10
        ) { (status, location, geofences) in
            print("Search geofences: status = \(Radar.stringForStatus(status)); geofences = \(String(describing: geofences))")
        }
        
        Radar.searchPoints(
            radius: 1000,
            tags: ["article"],
            limit: 10
        ) { (status, location, points) in
            print("Search points: status = \(Radar.stringForStatus(status)); points = \(String(describing: points))")
        }

        Radar.geocode(address: "20 jay st brooklyn") { (status, addresses) in
            print("Geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
        }

        Radar.reverseGeocode { (status, addresses) in
            print("Reverse geocode: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
        }

        Radar.ipGeocode { (status, address) in
            print("IP geocode: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city))")
        }
        
        let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
        let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)

        Radar.autocomplete(
            query: "brooklyn roasting",
            near: origin,
            limit: 10
        ) { (status, addresses) in
            print("Autocomplete: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
        }

        Radar.getDistance(
            origin: origin,
            destination: destination,
            modes: [.foot, .car],
            units: .imperial
        ) { (status, routes) in
            print("Distance: status = \(Radar.stringForStatus(status)); routes.car.distance.value = \(String(describing: routes?.car?.distance.value)); routes.car.distance.text = \(String(describing: routes?.car?.distance.text)); routes.car.duration.value = \(String(describing: routes?.car?.duration.value)); routes.car.duration.text = \(String(describing: routes?.car?.duration.text))")
        }*/
        
        let origin = CLLocation(latitude: 40.71344, longitude: -74.03558)
        let destination = CLLocation(latitude: 40.72039, longitude: -74.04683)
        
        Radar.mockTracking(
            origin: origin,
            destination: destination,
            mode: .foot,
            points: 20,
            interval: 2
        ) { (status, location, events, user) in
            print("Mock track: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
        }

        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

    func notify(_ body: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                let content = UNMutableNotificationContent()
                content.body = body
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = "example"

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
            }
        }
    }

    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser) {
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
        self.notify(Utils.stringForRadarStatus(status))
    }

    func didLog(message: String) {
        self.notify(message)
    }

}
