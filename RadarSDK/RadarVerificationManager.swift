//
//  RadarVerificationManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Network

@objc protocol RadarVerificationManagerSwiftHost: AnyObject {
    var startedInterval: TimeInterval { get set }
    var startedBeacons: Bool { get set }
    var intervalTimer: Timer { get set }
    var monitor: nw_path_monitor_t { get set }
    var lastToken: RadarVerifiedLocationToken { get set }
    var lastTokenSystemUptime: TimeInterval { get set }
    var lastTokenBeacons: Bool { get set }
    var lastIPs: String { get set }
    var lastIPChangeDeliveredAt: TimeInterval { get set }
    var expectedCountryCode: String { get set }
    var expectedStateCode: String { get set }
}


@objc(RadarVerificationManagerSwift)
@objcMembers
public final class RadarVerificationManager: NSObject, @unchecked Sendable {
    
    @objc(sharedInstance)
    static let shared = RadarVerificationManager(
        apiClient: RadarAPIClient.shared,
        fraudSDK: RadarSDKFraud.shared,
        locationManagerHost: {
            guard let clas = NSClassFromString("RadarLocationManager") as? NSObject.Type else {
                return nil
            }
            let sharedInstanceSelector = NSSelectorFromString("sharedInstance")
            guard clas.responds(to: sharedInstanceSelector),
                let result = clas.perform(sharedInstanceSelector),
                let instance = result.takeRetainedValue() as? RadarLocationManagerSwiftHost
            else {
                return nil
            }
            return instance
        }(),
        verificationmanagerHost: {
            guard let clas = NSClassFromString("RadarVerificationManager") as? NSObject.Type else {
                return nil
            }
            let sharedInstanceSelector = NSSelectorFromString("sharedInstance")
            guard clas.responds(to: sharedInstanceSelector),
                let result = clas.perform(sharedInstanceSelector),
                let instance = result.takeRetainedValue() as? RadarVerificationManagerSwiftHost
            else {
                return nil
            }
            return instance
        }()
    )

    let apiClient: RadarAPIClient
    let fraudSDK: RadarSDKFraud?
    let locationManagerHost: RadarLocationManagerSwiftHost?
    let verificationmanagerHost: RadarVerificationManagerSwiftHost?
    
    private let sharingLock = NSLock()
    private var lastToken: RadarVerifiedLocationToken? = nil
    private var lastTokenSystemUptime: TimeInterval = 0
    private var expectedStateCode: String? = nil
    private var expectedCountryCode: String? = nil
    
    init(apiClient: RadarAPIClient,
         fraudSDK: RadarSDKFraud?,
         locationManagerHost: RadarLocationManagerSwiftHost?,
         verificationmanagerHost: RadarVerificationManagerSwiftHost?) {
        self.apiClient = apiClient
        self.fraudSDK = fraudSDK
        self.locationManagerHost = locationManagerHost
        self.verificationmanagerHost = verificationmanagerHost
    }
    
    public func trackVerified() async -> (RadarStatus, RadarVerifiedLocationToken?) {
        return await trackVerified(beacons: false, desiredAccuracy: .medium, reason: nil, transactionId: nil)
    }
    
    public func trackVerified(beacons: Bool, desiredAccuracy: RadarTrackingOptionsDesiredAccuracy, reason: String?, transactionId: String?) async -> (RadarStatus, RadarVerifiedLocationToken?) {
        
        guard let locationManagerHost else {
            // locationManagerHost must exist
            return (.errorUnknown, nil)
        }
        
        
        let reason = reason ?? "manual"
        let foreground = await RadarUtils.foreground
        let autoFailover = RadarSettings.initializeOptions?.trackVerifiedAutoFailover ?? false
        
        async let locationPromise = RadarLocationManagerSwift.getLocation(host: locationManagerHost, authorizationStatus: .authorizedAlways)
        
        // TODO: complete
        var config: RadarConfig?
        do {
            let config = try await apiClient.getConfig(usage: "verify", host: .verifiedHost)
        } catch {
            
        }
        
        
        
        let location = await locationPromise
        
        
        return (.success, nil)
    }
    
    public func startTrackingVerified(interval: TimeInterval) {
        
    }
    
    func stopTrackingVerified() {
        
    }
    
    func updateMonitoringState() {
        
    }
    
    func getVerifiedLocationToken(beacons: Bool, desiredAccuracy: RadarTrackingOptionsDesiredAccuracy) async -> RadarVerifiedLocationToken? {
        
        return nil
    }
    
    func clearVerifiedLocationToken() {
        sharingLock.lock()
        lastToken = nil
        sharingLock.unlock()
    }
    
    func isLastTokenValid() -> Bool {
        sharingLock.lock()
        let lastToken = self.lastToken
        let lastTokenSystemUptime = self.lastTokenSystemUptime
        sharingLock.unlock()
        
        guard let lastToken else {
            return false
        }
        
        let lastDistanceToStateBorder = lastToken.user?.state?.distanceToBorder ?? -1
        let timeElapsed = ProcessInfo.processInfo.systemUptime - lastTokenSystemUptime
        let tokenPassed = lastToken.passed
        
        let tokenValid = lastDistanceToStateBorder > 1609 && timeElapsed < lastToken.expiresIn && tokenPassed
        
        RadarLogger.debug("Last token \(tokenValid ? "valid" : "invalid") | lastToken.expiresIn = \(lastToken.expiresIn); lastTokenElapsed = \(timeElapsed); lastToken.passed = \(lastToken.passed); lastDistanceToStateBorder = \(lastDistanceToStateBorder)")
        
        return tokenValid
    }
    
    func setExpectedJurisdiction(countryCode: String, stateCode: String) {
        sharingLock.lock()
        self.expectedStateCode = stateCode
        self.expectedCountryCode = countryCode
        // set expected state + country code for objc instance
        // can be removed after full migration to swift
        verificationmanagerHost?.expectedStateCode = stateCode
        verificationmanagerHost?.expectedCountryCode = countryCode
        sharingLock.unlock()
    }
    
    func isSharing() -> Bool {
        return fraudSDK?.isSharing() ?? false
    }
    
    func clearSharing() {
        fraudSDK?.clearSharing()
    }
}
