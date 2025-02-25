//
//  AppDelegate.swift
//  Example
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import UIKit
import UserNotifications
import RadarSDK

// Helper function to check if a point is inside a polygon
func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
    var inside = false
    var j = polygon.count - 1
    
    for i in 0..<polygon.count {
        let pi = polygon[i]
        let pj = polygon[j]
        
        if ((pi.longitude > point.longitude) != (pj.longitude > point.longitude)) &&
            (point.latitude < (pj.latitude - pi.latitude) * (point.longitude - pi.longitude) / 
             (pj.longitude - pi.longitude) + pi.latitude) {
            inside = !inside
        }
        j = i
    }
    return inside
}

// Helper function to check if a circle intersects with a polygon
func doesCircleIntersectPolygon(center: CLLocationCoordinate2D, radius: CLLocationDistance, polygon: [CLLocationCoordinate2D]) -> Bool {
    // First, check if center point is inside polygon
    if isPointInPolygon(point: center, polygon: polygon) {
        return true
    }
    
    // Then check if any polygon edge intersects with circle
    for i in 0..<polygon.count {
        let start = polygon[i]
        let end = polygon[(i + 1) % polygon.count]
        
        // Convert coordinates to meters for distance calculation
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        // Calculate distance from center to line segment
        let distance = centerLocation.distance(from: startLocation)
        if distance <= radius {
            return true
        }
    }
    
    return false
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIWindowSceneDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, RadarDelegate, RadarVerifiedDelegate {

    let locationManager = CLLocationManager()
    var window: UIWindow? // required for UIWindowSceneDelegate
    
    var scrollView: UIScrollView?
    var demoFunctions = Array<(UIButton) -> Void>()

    var geofenceButtons: [String: UIButton] = [:] // geofenceId -> button

    var onPredictionUpdate: ((String, Double) -> Void)?

    weak var mapViewController: MapViewController?  // Make it weak to avoid retain cycles

    // store copy of geofences (mapview will also fetch/have a copy)
    var fetchedGeofences: [(String, String, [[CLLocationCoordinate2D]], String)] = []

    func fetchAllGeofences(callback: @escaping ([(String, String, [[CLLocationCoordinate2D]], String)]) -> Void) {
        let API_KEY = "prj_test_sk_26576f21c9ddd02079383a63ae06ee33fbde4f5f"
        let URL = "https://api.radar.io/v1/geofences?limit=1000"
        
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
                              let tag = geofence["tag"] as? String,
                              let enabled = geofence["enabled"] as? Bool,
                              enabled == true else {
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
        Radar.doIndoorSurvey(geofenceIdForSurvey, forLength: 60, isWhereAmIScan: false) { _, _ in
            print("done doIndoorSurvey")
            completion()  // Call the completion handler when done
        }
    }

    func startContinuousInference() {
        // WHERAMI HAS TO BE MORE THAN 5 SECONDS WHICH IS THE WINDOW
        Radar.doIndoorSurvey("WHEREAMI", forLength: 6, isWhereAmIScan:true) { serverResponse, locationAtStartOfSurvey in
            print("serverResponse", serverResponse)
            
            // response is now
            // {"response": {"67a3b1d57cfde39ce8ec226a": 0.8140016233766234, "67a40adf5d8fbe57279c9477": 0.1859983766233766}}
            // where every key is a geofenceId and the value is the probability

            if let data = serverResponse!.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let errorMessage = json["error"] as? String {
                    // If there's an error in the JSON, display it in the confidence label
                    DispatchQueue.main.async {
                        self.mapViewController?.confidenceLabel?.text = errorMessage
                    }
                } else if let responseDict = json["response"] as? [String: Double] {
                    // AT THIS POINT,
                    // we have self.fetchedGeofences which contains a list of geofence objects
                    // such as
                    // { "_id": "67a8f2a5767afb4e7e0861b8", "createdAt": "2025-02-09T18:23:33.992Z", "updatedAt": "2025-02-09T22:09:55.517Z", "live": false, "description": "ORD - Terminal 1 Lobby (Check-in/Security) - 1/3", "tag": "ord-lobbies", "externalId": "ord-t1-lobby-1/3", "type": "polygon", "mode": "car", "stopDetection": false, "geometryCenter": { "type": "Point", "coordinates": [ -87.90619381789712, 41.97952088933131 ] }, "geometryRadius": 42, "geometry": { "type": "Polygon", "coordinates": [ [ [ -87.90623854193908, 41.979889853742606 ], [ -87.90641417002996, 41.97918785152016 ], [ -87.90613812210665, 41.97913670012637 ], [ -87.90598443751283, 41.979869151936114 ], [ -87.90623854193908, 41.979889853742606 ] ] ] }, "ip": [], "enabled": true },
                    // AND in the response json object, we have all the geofences (known to the current ML model)
                    // with their probabilities.
                    // we want to FILTER OUT geofences that are not nearby which is defined by
                    // the gps point in locationAtStartOfSurvey BUT ALSO by its horizontal accuracy ie
                    // its the point + the "radius" of uncertainty around it
                    // that should intersect with all geofences (based on their geometries!) and then
                    // we should set the most probable geofence as the prediction

                    // print the entire length of fetchedgeofences
                    print("fetchedGeofences count", self.fetchedGeofences.count)
//                    print("locationAtStartOfSurvey", locationAtStartOfSurvey)
                    // print("locationAtStartOfSurvey.coordinate", locationAtStartOfSurvey.coordinate)
                    // print("locationAtStartOfSurvey.horizontalAccuracy", locationAtStartOfSurvey.horizontalAccuracy)

                    let nearbyGeofences = self.fetchedGeofences.filter { geofence in
                        let (_, _, polygons, _) = geofence
                        // Check each polygon in the geofence
                        return polygons.contains { polygon in
                            doesCircleIntersectPolygon(
                                center: locationAtStartOfSurvey.coordinate,
                                radius: locationAtStartOfSurvey.horizontalAccuracy,
                                polygon: polygon
                            )
                        }
                    }

                    print("nearbyGeofences count", nearbyGeofences.count)
                    
                    var highestProbability = 0.0
                    var mostLikelyGeofenceId = ""
                    
                    for (id, _, _, _) in nearbyGeofences {
                        if let probability = responseDict[id], probability > highestProbability {
                            highestProbability = probability
                            mostLikelyGeofenceId = id
                        }
                    }

                    if !mostLikelyGeofenceId.isEmpty {
                        DispatchQueue.main.async {
                            self.mapViewController?.handlePrediction(
                                geofenceId: mostLikelyGeofenceId,
                                confidence: highestProbability
                            )
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.mapViewController?.confidenceLabel?.text = "No nearby geofences found"
                        }
                    }

                    // print("got prediction", topPrediction, "probability", probability)
                    
                    // DispatchQueue.main.async {
                    //     self.mapViewController?.handlePrediction(geofenceId: topPrediction, confidence: probability)
                    // }

                    // LOOP
                    self.startContinuousInference()
                } else {
                    print("infer json parsing problem!!!")
                    // update the confidence label with the output text
                    DispatchQueue.main.async {
                        self.mapViewController?.confidenceLabel?.text = "Inference failed"
                    }
                }
            } else {
                print("infer json parsing problem!!!")
                // update the confidence label with the output text
                DispatchQueue.main.async {
                    self.mapViewController?.confidenceLabel?.text = "Inference failed"
                }
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

            print("fetching geofences!!!!!")
            self.fetchAllGeofences { geofences in
                DispatchQueue.main.async {
                    self.fetchedGeofences = geofences
                    button.setTitle("Running inference...", for: .normal)
                    self.startContinuousInference()
                }
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
