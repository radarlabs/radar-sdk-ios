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
        radarInitializeOptions.autoLogNotificationConversions = true
        radarInitializeOptions.autoHandleNotificationDeepLinks = true
        radarInitializeOptions.silentPush = true
        
        Radar.setAppGroup("group.waypoint.data")
        Radar.initialize(publishableKey: "prj_test_pk_", options: radarInitializeOptions )
        
        Radar.setMetadata([ "foo": "bar" ])
        Radar.setDelegate(self)
        Radar.setVerifiedDelegate(self)
        Radar.setInAppMessageDelegate(MyIAMDelegate())
        
        if #available(iOS 15.0, *) {
            locationManager.startMonitoringLocationPushes() { data, error in
                print("Extension Token", data?.map { String(format: "%02x", $0) }.joined() ?? "no token")
                Radar.setLocationExtensionToken(data?.map { String(format: "%02x", $0) }.joined() ?? "no token")
            }
        }
        
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
            //            Radar.getLocation { (status, location, stopped) in
            //                print("Location: status = \(Radar.stringForStatus(status)); location = \(String(describing: location))")
            //            }
            //
            //            Radar.trackOnce { (status, location, events, user) in
            //                print("Track once: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
            //            }
        }
        
        demoButton(text: "IAM") {
            Radar.showInAppMessage(RadarInAppMessage.fromDictionary([
                "title": [
                    "text": "This is the titleakfjaklsjdflajsldfjalsdjflajsldkfjaslkfdjkalsjdfklajlkfdjklsjflajsd",
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
        demoButton(text: "get User Id") {
            print(Radar.getUserId())
        }
        demoButton(text: "track once") {
            print(Radar.trackOnce())
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
        print(response)
    }
    
    // this function is called ONLY for silent-pushes
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        print(userInfo)
        
        return .newData
    }

    func notify(_ body: String) {
    }
}
