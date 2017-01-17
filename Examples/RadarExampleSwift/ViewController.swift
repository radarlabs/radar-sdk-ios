//
//  ViewController.swift
//  RadarExampleSwift
//
//  Copyright © 2017 Radar Labs, Inc. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController, RadarDelegate {
    
    var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.requestPermissions()
        
        Radar.setDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        stackView.center = CGPoint(x: self.view.frame.width / 2.0, y: self.stackView.frame.height / 2.0 + 64.0)
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.white
        
        let boldFont = UIFont.boldSystemFont(ofSize: 17)
        let normalFont = UIFont.systemFont(ofSize: 17)
        
        let userIdTitleLabel = UILabel()
        userIdTitleLabel.text = "User ID"
        userIdTitleLabel.font = boldFont
        
        let userIdLabel = UILabel()
        userIdLabel.text = Utils.getUserId()
        userIdLabel.font = normalFont
        
        let trackOnceButton = UIButton(type: .roundedRect)
        trackOnceButton.setTitle("Track Once", for: .normal)
        trackOnceButton.titleLabel?.font = boldFont
        trackOnceButton.addTarget(self, action: #selector(trackOnce(trackingButton:)), for: [.touchUpInside])
        
        let trackingTitleLabel = UILabel()
        trackingTitleLabel.text = "Tracking"
        trackingTitleLabel.font = boldFont
        
        let trackingSwitch = UISwitch()
        trackingSwitch.isOn = Radar.isTracking() && Radar.authorizationStatus() == .authorizedAlways
        trackingSwitch.addTarget(self, action: #selector(trackingChanged(trackingSwitch:)), for: .valueChanged)
        
        let arrangedSubviews = [
            userIdTitleLabel,
            userIdLabel,
            UIView(),
            trackOnceButton,
            UIView(),
            trackingTitleLabel,
            trackingSwitch
        ]
        
        self.stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        self.stackView.axis = .vertical
        self.stackView.alignment = .center
        self.stackView.distribution = .equalCentering
        self.stackView.spacing = 16.0
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.stackView)
    }
    
    func requestPermissions() {
        if Radar.authorizationStatus() == .notDetermined {
            Radar.requestAlwaysAuthorization()
        }
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { (granted: Bool, error: Error?) in
            
        }
    }
    
    func trackOnce(trackingButton: UIButton) {
        trackingButton.isEnabled = false
        
        Radar.trackOnce(completionHandler: { (status: RadarStatus, location: CLLocation?, events: [RadarEvent]?, user: RadarUser?) in
            DispatchQueue.main.async {
                trackingButton.isEnabled = true
                
                let statusString = Utils.stringForStatus(status)
                print(statusString)
                self.showAlert(title: statusString, message: nil)
                
                if status == .success {
                    if let user = user, let geofences = user.geofences {
                        for geofence in geofences {
                            let geofenceString = Utils.stringForGeofence(geofence)
                            print(geofenceString)
                        }
                    }
                    
                    if let events = events {
                        for event in events {
                            let eventString = Utils.stringForEvent(event)
                            print(eventString)
                        }
                    }
                }
            }
        })
    }
    
    func trackingChanged(trackingSwitch: UISwitch) {
        if trackingSwitch.isOn {
            Radar.startTracking()
        } else {
            Radar.stopTracking()
        }
    }
    
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser) {
        for event in events {
            let eventString = Utils.stringForEvent(event)
            self.showNotification(title: "Event", body: eventString)
        }
    }
    
    func didFail(status: RadarStatus) {
        let statusString = Utils.stringForStatus(status)
        print(statusString)
    }
    
    func showAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
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

