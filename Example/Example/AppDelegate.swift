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
    var demoFunctions = Array<() -> Void>()
    
    // UI elements for displaying altitude and timestamp
    var altitudeLabel: UILabel?
    var timestampLabel: UILabel?
    var metadataLabel: UILabel?
    var metadataTextView: UITextView?
    
    // UI elements for calibration altitude input
    var calibrationTextField: UITextField?
    var calibrationButton: UIButton?
    var currentCalibrationLabel: UILabel?

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
        Radar.initialize(publishableKey: "", options: radarInitializeOptions )
        Radar.setUserId("testUserId")
        // Radar.setMetadata([ "foo": "bar", "radar:calibrationAltitude": 40 ])
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
    
    func updateAltitudeDisplay(user: RadarUser?, location: CLLocation?) {
        DispatchQueue.main.async {
            if let user = user {
                let altitude = user.altitude
                let altitudeText = String(format: "Altitude: %.2f meters", altitude)
                self.altitudeLabel?.text = altitudeText
                
                // Display metadata key-value pairs
                if let metadata = user.metadata, !metadata.isEmpty {
                    let metadataText = metadata.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                    self.metadataTextView?.text = metadataText
                } else {
                    self.metadataTextView?.text = "None"
                }
            } else if let location = location {
                let altitude = location.altitude
                let altitudeText = String(format: "Altitude: %.2f meters", altitude)
                self.altitudeLabel?.text = altitudeText
                
                // Clear metadata display when only location is available
                self.metadataTextView?.text = "Location only"
            }
            
            let timestamp = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            let timestampText = "Last Updated: \(formatter.string(from: timestamp))"
            self.timestampLabel?.text = timestampText
        }
    }
    
    @objc func setCalibrationAltitude() {
        guard let text = calibrationTextField?.text, !text.isEmpty else {
            // Show error for empty input
            print("Please enter a valid altitude value")
            return
        }
        
        guard let altitude = Double(text), altitude >= 0 else {
            // Show error for invalid number
            print("Please enter a valid positive number")
            return
        }
        
        // Set the calibration altitude metadata
        Radar.setMetadata(["radar:calibrationAltitude": altitude])
        
        // Update the current calibration label
        currentCalibrationLabel?.text = "Current: \(altitude) meters"
        
        // Update the metadata display to show the new value
        metadataTextView?.text = "radar:calibrationAltitude: \(altitude)"
        
        // Clear the text field
        calibrationTextField?.text = ""
        
        // Show confirmation
        print("Calibration altitude set to: \(altitude) meters")
        
        // Optional: Update the altitude display to show the new calibration
        // This will be reflected in future trackOnce calls
    }
    
    @objc func dismissKeyboard() {
        calibrationTextField?.resignFirstResponder()
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        
        window.backgroundColor = .white
        
        // Create altitude and timestamp labels
        altitudeLabel = UILabel(frame: CGRect(x: 20, y: 50, width: window.frame.size.width - 40, height: 30))
        altitudeLabel?.text = "Altitude: --"
        altitudeLabel?.textAlignment = .center
        altitudeLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        altitudeLabel?.textColor = .darkGray
        
        timestampLabel = UILabel(frame: CGRect(x: 20, y: 80, width: window.frame.size.width - 40, height: 30))
        timestampLabel?.text = "Last Updated: Never"
        timestampLabel?.textAlignment = .center
        timestampLabel?.font = UIFont.systemFont(ofSize: 14)
        timestampLabel?.textColor = .lightGray
        
        // Create calibration altitude input UI
        let calibrationLabel = UILabel(frame: CGRect(x: 20, y: 110, width: window.frame.size.width - 40, height: 20))
        calibrationLabel.text = "Calibration Altitude (meters):"
        calibrationLabel.textAlignment = .center
        calibrationLabel.font = UIFont.systemFont(ofSize: 12)
        calibrationLabel.textColor = .darkGray
        
        // Label to display current calibration altitude value
        currentCalibrationLabel = UILabel(frame: CGRect(x: 20, y: 130, width: window.frame.size.width - 40, height: 30))
        currentCalibrationLabel?.text = "Current: Not set"
        currentCalibrationLabel?.textAlignment = .center
        currentCalibrationLabel?.font = UIFont.systemFont(ofSize: 11)
        currentCalibrationLabel?.textColor = .lightGray
        
        calibrationTextField = UITextField(frame: CGRect(x: 20, y: 165, width: window.frame.size.width - 40, height: 30))
        calibrationTextField?.placeholder = "Enter altitude in meters"
        calibrationTextField?.borderStyle = .roundedRect
        calibrationTextField?.keyboardType = .decimalPad
        calibrationTextField?.textAlignment = .center
        
        calibrationButton = UIButton(frame: CGRect(x: 20, y: 200, width: window.frame.size.width - 40, height: 30))
        calibrationButton?.setTitle("Set Calibration Altitude", for: .normal)
        calibrationButton?.setTitleColor(.white, for: .normal)
        calibrationButton?.backgroundColor = .systemBlue
        calibrationButton?.layer.cornerRadius = 5
        calibrationButton?.addTarget(self, action: #selector(setCalibrationAltitude), for: .touchUpInside)
        

        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        window.addGestureRecognizer(tapGesture)
        
        // Position scroll view for demo buttons
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 240, width: window.frame.size.width, height: window.frame.size.height * 0.35))
        
        // Create metadata section at the bottom
        let metadataY = scrollView!.frame.maxY + 10
        let metadataHeight = window.frame.height - metadataY - 20 // Leave some padding at bottom
        
        // Create metadata section header
        metadataLabel = UILabel(frame: CGRect(x: 20, y: metadataY, width: window.frame.size.width - 40, height: 20))
        metadataLabel?.text = "Metadata:"
        metadataLabel?.textAlignment = .left
        metadataLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        metadataLabel?.textColor = .darkGray
        
        // Create scrollable metadata text view
        metadataTextView = UITextView(frame: CGRect(x: 20, y: metadataY + 25, width: window.frame.size.width - 40, height: metadataHeight - 25))
        metadataTextView?.text = "None"
        metadataTextView?.font = UIFont.systemFont(ofSize: 12)
        metadataTextView?.textColor = .darkGray
        metadataTextView?.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        metadataTextView?.layer.cornerRadius = 5
        metadataTextView?.isEditable = false
        metadataTextView?.isScrollEnabled = true
        metadataTextView?.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        scrollView!.contentSize.height = 0
        scrollView!.contentSize.width = window.frame.size.width

        window.addSubview(altitudeLabel!)
        window.addSubview(timestampLabel!)
        window.addSubview(metadataLabel!)
        window.addSubview(metadataTextView!)
        window.addSubview(calibrationLabel)
        window.addSubview(currentCalibrationLabel!)
        window.addSubview(calibrationTextField!)
        window.addSubview(calibrationButton!)
        
        window.addSubview(scrollView!)
        
        window.makeKeyAndVisible()
        
        self.window = window
        
        if UIApplication.shared.applicationState != .background {
            Radar.getLocation { (status, location, stopped) in
                print("Location: status = \(Radar.stringForStatus(status)); location = \(String(describing: location))")
            }

            Radar.trackOnce { (status, location, events, user) in
                print("Track once: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
                self.updateAltitudeDisplay(user: user, location: location)
            }
        }

        demoButton(text: "clear metadata") {
            Radar.setMetadata([:])
            // Reset the current calibration label
            self.currentCalibrationLabel?.text = "Current: Not set"
            // Reset the metadata display
            self.metadataTextView?.text = "None"
        }

        demoButton(text: "request motion activity permission") {
            Radar.requestMotionActivityPermission()
        }
        
        demoButton(text: "TrackOnce") {
            Radar.trackOnce { (status, location, events, user) in
                print("Track once: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
                self.updateAltitudeDisplay(user: user, location: location)
            }
        }


        demoButton(text: "startTracking") {
            let options = RadarTrackingOptions.presetContinuous
            Radar.startTracking(trackingOptions: options)
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Uncomment for manual setup for notification conversions and URLs
        // Radar.logConversion(response: response)
        // Radar.openURLFromNotification(response.notification)
    }

    func notify(_ body: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                let content = UNMutableNotificationContent()
                content.body = body
                content.sound = UNNotificationSound.default
                content.categoryIdentifier = "example"

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                //UNUserNotificationCenter.current().add(request, withCompletionHandler: { (_) in })
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
        self.updateAltitudeDisplay(user: user, location: location)
    }

    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        let body = "\(stopped ? "Client stopped at" : "Client moved to") location (\(location.coordinate.latitude), \(location.coordinate.longitude)) with accuracy \(location.horizontalAccuracy) meters and source \(Utils.stringForRadarLocationSource(source))"
        self.notify(body)
        self.updateAltitudeDisplay(user: nil, location: location)
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
