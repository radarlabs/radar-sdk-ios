//
//  RadarVerifyServer.swift
//  RadarSDK
//
//  Created by Nick Patrick on 11/11/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Telegraph
import UserNotifications

@objc(RadarVerifyServer) class RadarVerifyServer: NSObject, CLLocationManagerDelegate {
    @MainActor @objc static let sharedInstance = RadarVerifyServer()
    
    private let certificateURL = URL(string: "https://s3.us-east-2.amazonaws.com/app.radar-verify.com/mac/c.der")!
    private let identityURL = URL(string: "https://s3.us-east-2.amazonaws.com/app.radar-verify.com/mac/id.p12")!
    
    private var locationManager = CLLocationManager()
    private var server: Server?
    
    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 3000
    }
    
    private func addHeaders(to response: HTTPResponse) {
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Accept, Authorization, X-Radar-Device-Type, X-Radar-SDK-Version"
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
    }
    
    @objc func startServer() {
        do {
            guard let identity = CertificateIdentity(p12URL: identityURL),
                  let caCertificate = Certificate(derURL: certificateURL) else {
                print("Failed to start server: Error downloading certificates")
                return
            }
            
            server = Server(identity: identity, caCertificates: [caCertificate])
            
            self.server?.route(.OPTIONS, "/v1/verify") { _ in
                let response = HTTPResponse(.ok)
                self.addHeaders(to: response)
                return response
            }
            
            self.server?.route(.GET, "/v1/verify") { request in
                let userId = request.params["userId"]
                let description = request.params["description"]
                
                Radar.setUserId(userId)
                Radar.setDescription(description)
                
                var response = HTTPResponse(.internalServerError)
                
                let semaphore = DispatchSemaphore(value: 0)
                
                self.showNotification(title: "Location check in progress...")
                
                Radar.trackVerified { status, token in
                    if status == .success, let rawDict = token?.rawDict {
                        do {
                            let mutableDict = NSMutableDictionary(dictionary: rawDict)
                            mutableDict["meta"] = ["code": 200]
                            
                            let data = try JSONSerialization.data(withJSONObject: mutableDict)
                            
                            if let content = String(data: data, encoding: .utf8) {
                                response = HTTPResponse(.ok, content: content)
                            }
                        } catch {
                            
                        }
                    } else if status == .errorUnauthorized {
                        response = HTTPResponse(.unauthorized)
                    } else if status == .errorForbidden {
                        response = HTTPResponse(.forbidden)
                    } else if status == .errorPaymentRequired {
                        response = HTTPResponse(.paymentRequired)
                    } else if status == .errorPermissions {
                        let content = "{\"meta\":{\"code\":400,\"error\":\"ERROR_PERMISSIONS\"}}"
                        response = HTTPResponse(.badRequest, content: content)
                    } else if status == .errorLocation {
                        let content = "{\"meta\":{\"code\":400,\"error\":\"ERROR_LOCATION\"}}"
                        response = HTTPResponse(.badRequest, content: content)
                    } else if status == .errorNetwork {
                        let content = "{\"meta\":{\"code\":400,\"error\":\"ERROR_NETWORK\"}}"
                        response = HTTPResponse(.badRequest, content: content)
                    }
                    semaphore.signal()
                }
                
                semaphore.wait()
                
                self.addHeaders(to: response)
                return response
            }
            
            self.locationManager.startUpdatingLocation()
            try self.server?.start(port: 52516, interface: "127.0.0.1")
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    @objc func stopServer() {
        self.server?.stop()
        self.server = nil
        self.locationManager.stopUpdatingLocation()
    }
    
    private func showNotification(title: String? = nil, body: String? = nil) {
        let content = UNMutableNotificationContent()
        if let title = title { content.title = title }
        if let body = body { content.body = body }
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    private func downloadData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
}
