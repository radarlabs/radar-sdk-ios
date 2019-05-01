//
//  AppDelegate.swift
//  RadarExampleSwift
//
//  Copyright © 2017 Radar Labs, Inc. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RadarDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let publishableKey = "" // replace with your publishable API key
        Radar.initialize(publishableKey: publishableKey)
        
        let userId = Utils.getUserId()
        Radar.setUserId(userId)
        
        Radar.setDelegate(self)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = ViewController()
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser) {
        for event in events {
            let eventString = Utils.stringForEvent(event)
            self.showNotification(title: "Event", body: eventString)
        }
    }
    
    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        let state = user.stopped ? "Stopped at" : "Moved to"
        let locationString = "\(state) location (\(location.coordinate.latitude), \(location.coordinate.longitude)) with accuracy \(location.horizontalAccuracy) meters"
        self.showNotification(title: "Location", body: locationString)
    }
    
    func didFail(status: RadarStatus) {
        let statusString = Utils.stringForStatus(status)
        self.showNotification(title: "Error", body: statusString)
    }
    
    func showNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        
        let identifier = body
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request, withCompletionHandler: { (error: Error?) in
            
        })
    }

}

