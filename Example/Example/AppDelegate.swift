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
class AppDelegate: UIResponder, UIApplicationDelegate, UIWindowSceneDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, RadarDelegate, RadarVerifiedDelegate {

    let locationManager = CLLocationManager()
    var window: UIWindow? // required for UIWindowSceneDelegate
    
    var scrollView: UIScrollView?
    var demoFunctions = Array<(UIButton) -> Void>()

    var geofenceButtons: [String: UIButton] = [:] // geofenceId -> button

    var onPredictionUpdate: ((String, Double) -> Void)?

    weak var mapViewController: MapViewController?  // Make it weak to avoid retain cycles

    func fetchAllGeofences(callback: @escaping ([(String, String, [[CLLocationCoordinate2D]], String)]) -> Void) {
        let API_KEY = "prj_test_sk_26576f21c9ddd02079383a63ae06ee33fbde4f5f"
        let URL = "https://api.radar.io/v1/geofences"
        
        let url = Foundation.URL(string: URL)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue(API_KEY, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let geofences = json["geofences"] as? [[String: Any]] else {
                        return
                    }
                    
                    let out: [(String, String, [[CLLocationCoordinate2D]], String)] = geofences.compactMap { geofence in
                        guard let id = geofence["_id"] as? String,
                              let description = geofence["description"] as? String,
                              let geometry = geofence["geometry"] as? [String: Any],
                              let coordinates = geometry["coordinates"] as? [[[Double]]],
                              let tag = geofence["tag"] as? String else {
                            return nil
                        }
                        
                        // Convert coordinates to CLLocationCoordinate2D
                        // Note: The first array in coordinates is the outer ring
                        let polygonCoordinates = coordinates[0].map { coord in
                            // GeoJSON format is [longitude, latitude]
                            CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                        }
                        
                        return (id, description, [polygonCoordinates], tag)
                    }
                    
                    callback(out)
                } catch {
                    print("JSON parsing error: \(error)")
                }
            }
        }
        task.resume()
    }

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in }
        UNUserNotificationCenter.current().delegate = self
        
        locationManager.delegate = self
        self.requestLocationPermissions()
        
        // Replace with a valid test publishable key
        /*
        Radar.initialize(publishableKey: "prj_test_pk_0000000000000000000000000000000000000000")
        Radar.setUserId("testUserId")
        Radar.setMetadata([ "foo": "bar" ])
        Radar.setDelegate(self)
        Radar.setVerifiedDelegate(self)
        */
        
        return true
    }
    
    func demoButton(text: String, function: @escaping (UIButton) -> Void) {
        guard let scrollView = self.scrollView else { return }
        
        let buttonHeight = 50
        scrollView.contentSize.height += CGFloat(buttonHeight)
        
        let buttonFrame = CGRect(x: 0, y: demoFunctions.count * buttonHeight, width: Int(scrollView.frame.width), height: buttonHeight)
        let button = UIButton(frame: buttonFrame)
        button.addAction(UIAction(handler: { _ in
            function(button)
        }), for: .touchUpInside)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        button.setTitle(text, for: .normal)
        
        demoFunctions.append(function)
        
        scrollView.addSubview(button)
    }
    
    @objc func didTapGeofenceButton(_ geofenceId: String, _ description: String, completion: @escaping () -> Void) {
        print("tapped geofence button")
        print(geofenceId, description)

        let geofenceIdForSurvey = "geofenceid:\(geofenceId)"
        Radar.doIndoorSurvey(geofenceIdForSurvey, forLength: 60, isWhereAmIScan: false) { _ in
            print("done doIndoorSurvey")
            completion()  // Call the completion handler when done
        }
    }

    func startContinuousInference() {
        // WHERAMI HAS TO BE MORE THAN 5 SECONDS WHICH IS THE WINDOW
        Radar.doIndoorSurvey("WHEREAMI", forLength: 6, isWhereAmIScan:true) { output in
            print("output", output)
            
            // Parse the JSON string
            if let data = output!.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               // response is now
               // {"response": ["67a3b1d57cfde39ce8ec226a", 0.9940016233766232]}
               let response = json["response"] as? [Any],
               let topPrediction = response[0] as? String,
                let probability = response[1] as? Double
               {
                print("got prediction", topPrediction, "probability", probability)
                
                DispatchQueue.main.async {
                    self.mapViewController?.handlePrediction(geofenceId: topPrediction, confidence: probability)
                }

                // LOOP
                self.startContinuousInference()
            } else {
                print("infer json parsing problem!!!")
            }
        }
    }


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        
        
        // Add MapViewController
        let mapViewController = MapViewController()
        self.mapViewController = mapViewController  // Store strong reference
        window.addSubview(mapViewController.view)
    
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 700, width: window.frame.size.width, height: window.frame.size.height - 300))
        scrollView!.contentSize.height = 0
        scrollView!.contentSize.width = window.frame.size.width
        
        window.addSubview(scrollView!)
        
        window.makeKeyAndVisible()
        
        self.window = window
       
        demoButton(text: "Start Infer Forever Loop") { button in
            button.setTitle("Running inference...", for: .normal)
            self.startContinuousInference()
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
        completionHandler([.list, .banner, .sound])
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
