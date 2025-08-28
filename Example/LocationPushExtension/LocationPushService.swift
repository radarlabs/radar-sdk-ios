//
//  LocationPushService.swift
//  LocationPushExtension
//
//  Created by ShiCheng Lu on 8/28/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

class LocationPushService: NSObject, CLLocationPushServiceExtension, CLLocationManagerDelegate {

    var completion: (() -> Void)?
    var locationManager: CLLocationManager?

    func didReceiveLocationPushPayload(_ payload: [String : Any], completion: @escaping () -> Void) {
        self.completion = completion
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.locationManager!.requestLocation()
        
        let url = URL(string: "https://webhook.site/151ee0ed-2d30-49a4-8060-ab72e0ba9b47/didReceiveLocationPushPayload")!
        let task = URLSession.shared.dataTask(with: url) { (_, _, _) in }
        task.resume()
        
        
        
        
        
        print("did receive push payload", payload)
    }
    
    func serviceExtensionWillTerminate() {
        // Called just before the extension will be terminated by the system.
        
        print("Terminated")
        
        self.completion?()
    }

    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process the location(s) as appropriate
        // let location = locations.first

        // If sharing the locations to another user, end-to-end encrypt them to protect privacy
        print("got location")
        
        let url = URL(string: "https://webhook.site/151ee0ed-2d30-49a4-8060-ab72e0ba9b47/didUpdateLocations")!
        let task = URLSession.shared.dataTask(with: url) { (_, _, _) in }
        task.resume()
        
        
        
        // When finished, always call completion()
        self.completion?()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        let url = URL(string: "https://webhook.site/151ee0ed-2d30-49a4-8060-ab72e0ba9b47/didFailWithError")!
        let task = URLSession.shared.dataTask(with: url) { (_, _, _) in }
        task.resume()
        print("Failed")
        self.completion?()
    }

}
