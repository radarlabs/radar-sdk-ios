//
//  RadarVerifyServer.swift
//  RadarSDK
//
//  Created by Nick Patrick on 11/11/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UserNotifications

#if canImport(Telegraph)
import Telegraph

@objc(RadarVerifyServer) class RadarVerifyServer: NSObject, CLLocationManagerDelegate {
    @MainActor @objc static let sharedInstance = RadarVerifyServer()
    
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
    
    @objc func startServer(withCertData certData: Data, identityData: Data) {
        do {
            guard let identity = CertificateIdentity(p12Data: identityData),
                  let caCertificate = Certificate(derData: certData) else {
                RadarLogger.sharedInstance().log(with: .debug, message: "Error starting server: error parsing cert data")
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
            
            RadarLogger.sharedInstance().log(with: .debug, message: "Starting server | interface = 127.0.0.1; port = 52516")
            
            try self.server?.start(port: 52516, interface: "127.0.0.1")
        } catch {
            RadarLogger.sharedInstance().log(with: .error, message: "Error starting server | error = \(error)")
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
    
    private func downloadData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }

    
}
#else
@objc(RadarVerifyServer) class RadarVerifyServer: NSObject {
    @MainActor @objc static let sharedInstance = RadarVerifyServer()
    
    @objc func startServer(withCertData certData: Data, identityData: Data) {
        RadarLogger.sharedInstance().log(with: .debug, message: "Error starting server: missing dependencies")
    }
    
    @objc func stopServer() {
        RadarLogger.sharedInstance().log(with: .debug, message: "Error stopping server: missing dependencies")
    }
    
}
#endif
