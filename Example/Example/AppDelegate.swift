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
        let API_KEY = "prj_test_sk_5f5fe073c141f17071f003be0e4388f92fea3b43" // Replace with your Radar secret key
        let URL = "https://api-vivan.radar-staging.com/v1/geofences?limit=1000"
        
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
    
    // used in simulator as a replacement for the sdk survey
    func waitThenCall(completion: @escaping () -> Void) {
        // Create a dispatch queue
        let queue = DispatchQueue.global(qos: .background)
        
        queue.asyncAfter(deadline: .now() + 10.0) {
            // Execute the callback on the main thread
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    private func getSavedSurveyorName() -> String? {
        return UserDefaults.standard.string(forKey: "radar_surveyor_name")
    }
    
    private func saveSurveyorName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "radar_surveyor_name")
        UserDefaults.standard.synchronize()
    }

    private func resetSurveyButton(_ button: UIButton) {
        DispatchQueue.main.async {
            button.isEnabled = true
            button.alpha = 1.0
            button.setTitle("Survey", for: .normal)
        }
    }

    private var currentSurveyCompletion: (() -> Void)?
    
    private func showErrorAlert(title: String, message: String) {
        // TODO: (vivan) Fix alert handling issues:
        // 1. UIApplication.shared.windows is deprecated since iOS 13.0
        // 2. Should use scene-based approach for iOS 13+
        // 3. Alert presentation logic should be moved to view controllers
        DispatchQueue.main.async {
            let errorAlert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
               let rootViewController = window.rootViewController {
                var topController = rootViewController
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                
                topController.present(errorAlert, animated: true)
            }
        }
    }
    
    @objc func didTapGeofenceButton(_ geofenceId: String, _ description: String, button: UIButton? = nil, completion: @escaping () -> Void) {
        print("tapped geofence button")
        print(geofenceId, description)
       
#if targetEnvironment(simulator)
        waitThenCall(completion: completion)
#else
        let alertController = UIAlertController(
            title: "New Survey",
            message: "Geofence: \(description)",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "Survey description (optional)"
        }
        
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "Your name"
            if let savedName = self?.getSavedSurveyorName() {
                textField.text = savedName
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            if let button = button {
                self.resetSurveyButton(button)
            }
            completion()
        }
        
        let submitAction = UIAlertAction(title: "Start Survey", style: .default) { [weak self] _ in
            guard let self = self else {
                if let button = button {
                    self?.resetSurveyButton(button)
                }
                completion()
                return
            }
            

            guard let descriptionTextField = alertController.textFields?[0],
                  let surveyorTextField = alertController.textFields?[1] else {
                if let button = button {
                    self.resetSurveyButton(button)
                }
                completion()
                return
            }
            
            guard let surveyorName = surveyorTextField.text, !surveyorName.isEmpty else {
                if let button = button {
                    self.resetSurveyButton(button)
                }
                
                self.showErrorAlert(
                    title: "Validation Error",
                    message: "Please enter your name."
                )
                
                completion()
                return
            }
            
            self.saveSurveyorName(surveyorName)
            
            let surveyDescription = descriptionTextField.text
            
            self.handleSurveyCreation(
                description: surveyDescription,
                geofenceId: geofenceId,
                surveyor: surveyorName,
                button: button,
                completion: completion
            )
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        
        // TODO: (vivan) Refactor alert presentation logic:
        // 1. Extract common "find top view controller" logic into helper method
        // 2. Use scene-based approach instead of deprecated UIApplication.shared.windows
        // 3. Consider passing view controller context instead of searching for it
        // Present the alert controller
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let rootViewController = window.rootViewController {
            
            // Get the topmost view controller (in case there are presented controllers)
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alertController, animated: true)
        } else {
            if let button = button {
                resetSurveyButton(button)
            }
            completion()
        }
#endif
    }

    private func handleSurveyCreation(description: String?, geofenceId: String, surveyor: String, button: UIButton? = nil, completion: @escaping () -> Void) {
        print("Starting survey: description: \(description ?? "nil"), geofence: \(geofenceId), surveyor: \(surveyor)")
        
        Radar.createIndoorSurvey(description: description, geofenceId: geofenceId, surveyor: surveyor) { [weak self] status, survey, uploadUrl in
            guard let self = self else {
                if let button = button {
                    self?.resetSurveyButton(button)
                }
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            guard status.rawValue == 0,
                  let survey = survey,
                  let surveyId = survey["_id"] as? String,
                  let uploadUrl = uploadUrl else {
                print("Failed to create survey with status: \(status.rawValue)")
                if let button = button {
                    self.resetSurveyButton(button)
                }
                
                self.showErrorAlert(
                    title: "Survey Creation Failed",
                    message: "Could not create new survey. Please try again later."
                )
                
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            print("Survey created with ID: \(surveyId)")
            
            let geofenceIdForSurvey = "geofenceid:\(geofenceId)"
            Radar.doIndoorSurvey(geofenceIdForSurvey, forLength: 60, isWhereAmIScan: false) { [weak self] result, locationAtStartOfSurvey in
                guard let self = self else {
                    if let button = button {
                        self?.resetSurveyButton(button)
                    }
                    
                    Radar.updateIndoorSurveyStatus(surveyId: surveyId, status: "failed") { _ in }
                    
                    DispatchQueue.main.async {
                        completion()
                    }
                    return
                }
                
                guard let surveyData = result else {
                    print("No survey data collected")
                    if let button = button {
                        self.resetSurveyButton(button)
                    }
                    
                    Radar.updateIndoorSurveyStatus(surveyId: surveyId, status: "failed") { _ in }
                    
                    self.showErrorAlert(
                        title: "Survey Data Collection Failed",
                        message: "Could not collect survey data. Please try again later."
                    )
                    
                    DispatchQueue.main.async {
                        completion()
                    }
                    return
                }
                
                print("Survey data collection complete with length: \(surveyData.count)")
                
                Radar.uploadIndoorSurveyData(base64EncodedData: surveyData, uploadUrl: uploadUrl) { [weak self] uploadStatus in
                    guard let self = self else {
                        if let button = button {
                            self?.resetSurveyButton(button)
                        }
                        
                        Radar.updateIndoorSurveyStatus(surveyId: surveyId, status: "failed") { _ in }
                        
                        DispatchQueue.main.async {
                            completion()
                        }
                        return
                    }
                    
                    guard uploadStatus.rawValue == 0 else { // RadarStatusSuccess
                        print("Failed to upload survey data with status: \(uploadStatus.rawValue)")
                        
                        Radar.updateIndoorSurveyStatus(surveyId: surveyId, status: "failed") { _ in }
                        
                        if let button = button {
                            self.resetSurveyButton(button)
                        }
                        
                        self.showErrorAlert(
                            title: "Survey Upload Failed",
                            message: "Could not upload survey data. Please try again later."
                        )
                        
                        DispatchQueue.main.async {
                            completion()
                        }
                        return
                    }
                    
                    print("Survey data uploaded successfully")
                    
                    Radar.updateIndoorSurveyStatus(surveyId: surveyId, status: "completed") { [weak self] completeStatus in
                        if completeStatus.rawValue != 0 {
                            print("Survey completion notification failed with status: \(completeStatus.rawValue)")
                            
                            // TODO: (vivan) Multiple alert presentation without coordination
                            self?.showErrorAlert(
                                title: "Survey Upload Successful",
                                message: "Survey data was uploaded successfully, but status notification failed. The survey will still be processed."
                            )
                        } else {
                            print("Survey status successfully updated to completed")
                        }
                    }
                    
                    if let button = button {
                        self.resetSurveyButton(button)
                    }
                    
                    // TODO: (vivan) This is using showErrorAlert for a success message, which is confusing
                    // Consider creating a separate showSuccessAlert method or a generic showAlert method
                    self.showErrorAlert(
                        title: "Survey Completed",
                        message: "Survey data has been successfully collected and uploaded."
                    )
                    
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
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
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        
        // Create the geofence picker adapter
        let geofenceAdapter = GeofencePickerAdapter()
        
        // Add MapViewController
        let mapViewController = MapViewController()
        self.mapViewController = mapViewController  // Store strong reference
        
        // Make sure we set the MapViewController as the root view controller
        window.rootViewController = mapViewController
        
        // Add scrollView to the mapViewController's view instead of the window
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 580, width: window.frame.size.width, height: window.frame.size.height - 300))
        scrollView!.contentSize.height = 0
        scrollView!.contentSize.width = window.frame.size.width
        
        mapViewController.view.addSubview(scrollView!)
        
        window.makeKeyAndVisible()
        
        self.window = window
        
        // Add a UI container for the dropdown and button
        let geofenceSelectionContainer = UIView(frame: CGRect(x: 0, y: 0, width: window.frame.size.width, height: 100))
        scrollView!.addSubview(geofenceSelectionContainer)
//        scrollView!.contentSize.height += 100

        // Create a dropdown button 
        let dropdownButton = UIButton(frame: CGRect(x: 10, y: 0, width: window.frame.size.width - 20, height: 40))
        dropdownButton.setTitle("Select a geofence...", for: .normal)
        dropdownButton.setTitleColor(.black, for: .normal)
        dropdownButton.contentHorizontalAlignment = .left
        dropdownButton.layer.borderWidth = 1
        dropdownButton.layer.borderColor = UIColor.lightGray.cgColor
        dropdownButton.layer.cornerRadius = 5
        dropdownButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        geofenceSelectionContainer.addSubview(dropdownButton)

        // Create a dropdown table view (initially hidden) - add to scroll view directly
        let dropdownTableView = UITableView(frame: CGRect(x: 10, y: 40, width: window.frame.size.width - 20, height: 180))
        dropdownTableView.register(UITableViewCell.self, forCellReuseIdentifier: "GeofenceCell")
        dropdownTableView.layer.borderWidth = 1
        dropdownTableView.layer.borderColor = UIColor.lightGray.cgColor
        dropdownTableView.isHidden = true

        // Set up table view data source and delegate
        let tableDelegate = TableViewDelegate()
        tableDelegate.onSelectItem = { (index, title) in
            if index < geofenceAdapter.geofences.count {
                let geofence = geofenceAdapter.geofences[index]
                geofenceAdapter.selectedIndex = index
                geofenceAdapter.selectedGeofence = (geofence.0, geofence.1)
                dropdownButton.setTitle(title, for: .normal)
                dropdownTableView.isHidden = true
            }
        }
        dropdownTableView.dataSource = tableDelegate
        dropdownTableView.delegate = tableDelegate
        scrollView!.addSubview(dropdownTableView)

        // Create the button for starting the survey - put it BELOW in the container
        let surveyButton = UIButton(frame: CGRect(x: 10, y: 50, width: window.frame.size.width - 20, height: 40))
        surveyButton.setTitle("Survey", for: .normal)
        surveyButton.setTitleColor(.white, for: .normal)
        surveyButton.backgroundColor = .systemBlue
        surveyButton.layer.cornerRadius = 5
        surveyButton.isUserInteractionEnabled = true

        surveyButton.adjustsImageWhenHighlighted = true
        surveyButton.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .highlighted)
        surveyButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)

        surveyButton.addAction(UIAction(handler: { _ in
            print("Survey button tapped", geofenceAdapter.selectedGeofence)

            if let selectedGeofence = geofenceAdapter.selectedGeofence {
                // Disable button during survey
                surveyButton.isEnabled = false
                surveyButton.alpha = 0.7  // Make it slightly transparent when disabled
                surveyButton.setTitle("Surveying...", for: .disabled)
                
                dropdownTableView.isHidden = true  // Now this reference is valid
                self.didTapGeofenceButton(selectedGeofence.0, selectedGeofence.1, button: surveyButton) {
                    print("Survey completed")
                    // Re-enable button after survey completes
                    DispatchQueue.main.async {
                        surveyButton.isEnabled = true
                        surveyButton.setTitle("Survey", for: .normal)
                    }
                }
            }
        }), for: .touchUpInside)
        geofenceSelectionContainer.addSubview(surveyButton)

        // Add action to button to show/hide dropdown
        dropdownButton.addAction(UIAction(handler: { _ in
            if dropdownTableView.isHidden {
                // Position the table view just below the dropdown button
                tableDelegate.items = geofenceAdapter.geofences.map { $0.1 }
                dropdownTableView.reloadData()
                dropdownTableView.isHidden = false
                // Bring the table view to front
                self.scrollView!.bringSubviewToFront(dropdownTableView)
            } else {
                dropdownTableView.isHidden = true
            }
        }), for: .touchUpInside)

        // Fetch geofences immediately
        self.fetchAllGeofences { geofences in
            DispatchQueue.main.async {
                self.fetchedGeofences = geofences
                
                // Sort the geofences alphabetically by description and update the adapter
                let sortedGeofences = geofences.sorted { $0.1 < $1.1 }
                geofenceAdapter.geofences = sortedGeofences
                
                // Set initial selection if available
                if !sortedGeofences.isEmpty {
                    geofenceAdapter.selectedIndex = 0
                    geofenceAdapter.selectedGeofence = (sortedGeofences[0].0, sortedGeofences[0].1)
                    dropdownButton.setTitle(sortedGeofences[0].1, for: .normal)
                }
            }
        }
        
        /*
        demoButton(text: "Start Infer Forever Loop") { button in
            button.setTitle("Running inference...", for: .normal)
            self.startContinuousInference()
        }
         */
    }

    // Add this class for handling the table view
    class TableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
        var items: [String] = []
        var onSelectItem: ((Int, String) -> Void)?
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GeofenceCell", for: indexPath)
            cell.textLabel?.text = items[indexPath.row]
            return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            onSelectItem?(indexPath.row, items[indexPath.row])
            tableView.deselectRow(at: indexPath, animated: true)
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

class GeofencePickerAdapter: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    var geofences: [(String, String, [[CLLocationCoordinate2D]], String)] = []
    var selectedGeofence: (String, String)? // (id, description)
    var selectedIndex: Int = 0
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return geofences.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return geofences[row].1 // Return the description
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if geofences.count > row {
            let geofence = geofences[row]
            selectedGeofence = (geofence.0, geofence.1) // (id, description)
        }
    }
}
