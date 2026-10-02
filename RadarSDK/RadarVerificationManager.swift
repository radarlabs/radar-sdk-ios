//
//  RadarVerificationManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarVerificationManagerSwiftHost)
protocol RadarVerificationManagerSwiftHost: AnyObject {
    var startedInterval: TimeInterval { get set }
    var startedBeacons: Bool { get set }
    var intervalTimer: Timer? { get set }
    var lastToken: RadarVerifiedLocationToken? { get set }
    var lastTokenSystemUptime: TimeInterval { get set }
    var lastTokenBeacons: Bool { get set }
    @objc(lastIPs) var lastIPs: String? { get set }
    var lastIPChangeDeliveredAt: TimeInterval { get set }
    var expectedCountryCode: String? { get set }
    var expectedStateCode: String? { get set }
    var swiftInstance: RadarVerificationManager? { get set }
}

@objc(RadarVerificationManagerSwift)
@objcMembers
final class RadarVerificationManager: NSObject, @unchecked Sendable {

    @objc(sharedInstance)
    static let shared = {
        let sharedLocationManager: RadarLocationManagerSwiftHost? = {
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
        }()

        let sharedVerificationManager: RadarVerificationManagerSwiftHost? = {
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

        let instance = RadarVerificationManager(
            apiClient: RadarAPIClient.shared,
            fraudSDK: RadarSDKFraud.shared,
            locationManagerHost: sharedLocationManager,
            verificationmanagerHost: sharedVerificationManager,
        )
        sharedVerificationManager?.swiftInstance = instance
        return instance
    }()

    let apiClient: RadarAPIClient
    let fraudSDK: RadarSDKFraud?
    let locationManagerHost: RadarLocationManagerSwiftHost?
    let verificationManagerHost: RadarVerificationManagerSwiftHost?
    let permissionHelper = RadarPermissionsHelperSwift()

    private let sharingLock = NSLock()

    // all properties are currently backed by the ObjectiveC instance, which can be directly translated to
    // swift properties once we complete migration of the entire class and verify correctness.
    private var lastToken: RadarVerifiedLocationToken? {
        get { return verificationManagerHost?.lastToken }
        set { verificationManagerHost?.lastToken = newValue }
    }
    private var lastTokenSystemUptime: TimeInterval {
        get { return verificationManagerHost?.lastTokenSystemUptime ?? 0 }
        set { verificationManagerHost?.lastTokenSystemUptime = newValue }
    }
    private var expectedStateCode: String? {
        get { return verificationManagerHost?.expectedStateCode }
        set { verificationManagerHost?.expectedStateCode = newValue }
    }
    private var expectedCountryCode: String? {
        get { return verificationManagerHost?.expectedCountryCode }
        set { verificationManagerHost?.expectedCountryCode = newValue }
    }
    private var lastTokenBeacons: Bool {
        get { return verificationManagerHost?.lastTokenBeacons ?? false }
        set { verificationManagerHost?.lastTokenBeacons = newValue }
    }

    init(
        apiClient: RadarAPIClient,
        fraudSDK: RadarSDKFraud?,
        locationManagerHost: RadarLocationManagerSwiftHost?,
        verificationmanagerHost: RadarVerificationManagerSwiftHost?
    ) {
        self.apiClient = apiClient
        self.fraudSDK = fraudSDK
        self.locationManagerHost = locationManagerHost
        self.verificationManagerHost = verificationmanagerHost
    }

    private func getLocation(withBeacons: Bool) async -> (RadarStatus, CLLocation?, [RadarBeacon]?) {
        guard let locationManagerHost, let fraudSDK else {
            return (.errorUnknown, nil, nil)
        }
        let authorizationStatus = permissionHelper.locationAuthorizationStatus()
        let (locationStatus, location, stopped) = await RadarLocationManagerSwift.getLocation(host: locationManagerHost, authorizationStatus: authorizationStatus)
        guard let location else {
            return (locationStatus, nil, nil)
        }

        let beaconResults = try? await apiClient.searchBeacons(near: location, radius: 1000, limit: 10)

        var beaconResult: [RadarBeacon]? = nil
        if let (beacons, beaconUUIDs) = beaconResults {
            RadarSettings.beaconUUIDs = beaconUUIDs
            if (beaconUUIDs.count != 0) {
                let (rangeStatus, rangeResult) = await RadarBeaconManagerSwift.shared.range(beaconUUIDs: beaconUUIDs)
                if (rangeStatus == .success) {
                    beaconResult = rangeResult
                }
            } else if (beacons.count != 0) {
                let (rangeStatus, rangeResult) = await RadarBeaconManagerSwift.shared.range(beacons: beacons)
                if (rangeStatus == .success) {
                    beaconResult = rangeResult
                }
            }
        }
        return (locationStatus, location, beaconResult)
    }
    
    
    public func trackVerified() async -> (RadarStatus, RadarVerifiedLocationToken?) {
        return await trackVerified(beacons: false, desiredAccuracy: .medium, transactionId: nil)
    }

    public func trackVerified(beacons: Bool, desiredAccuracy: RadarTrackingOptionsDesiredAccuracy, reason: String? = "manual", transactionId: String?) async -> (RadarStatus, RadarVerifiedLocationToken?) {
        guard let locationManagerHost, let fraudSDK else {
            return (.errorUnknown, nil)
        }
        
        sharingLock.withLock {
            self.lastTokenBeacons = beacons
        }
        
        let foreground = await RadarUtils.foreground
        let autoFailover = RadarSettings.initializeOptions?.trackVerifiedAutoFailover ?? false;
        
        // start location request
        async let locationPromise = getLocation(withBeacons: beacons)
        
        // start config request
        var config: RadarConfig? = nil
        var configError: RadarError? = nil
        do {
            config = try await apiClient.getConfig(usage: "verify", host: .verifiedHost)
        } catch let error as RadarError {
            configError = error
        } catch {
            // do nothing, uses secondary fallback if enabled
        }
        
        // secondary fallback
        if (config?.meta == nil && autoFailover) {
            RadarLogger.info("trackVerified: primary verified host returned non-Radar response, retrying on secondary")
            do {
                config = try await apiClient.getConfig(usage: "verify", host: .verifiedSecondaryHost)
            } catch let error as RadarError {
                configError = error
            } catch {
                // do nothing, second config check will return the error
            }
        }
        
        // still no config after fallback, return error
        if (config?.meta == nil) {
            RadarSwift.bridge?.didFail(status: configError?.status ?? .errorUnknown)
            return (configError?.status ?? .errorUnknown, nil)
        }
        
        // receive the location query we started
        let (locationStatus, location, stopped) = await locationPromise
        guard let location else {
            RadarSwift.bridge?.didFail(status: locationStatus)
            return (locationStatus, nil)
        }
        
        let (payloadStatus, payload) = await fraudSDK.getFraudPayload(options: [
            "location": location,
            "nonce": config?.nonce
        ])
        
        if (payload == nil) {
            return (.errorUnknown, nil)
        }
        
        let revealRiskId = RadarRevealRiskManager.shared.revealRiskId
        
        RadarAPIClient.track
        
        void (^callTrackAPI)(NSArray<RadarBeacon *> *_Nullable) = ^(NSArray<RadarBeacon *> *_Nullable beacons) {
        [[RadarAPIClient sharedInstance]
         trackWithLocation:location
         stopped:RadarState.stopped
         foreground:foreground
         source:RadarLocationSourceForegroundLocation
         replayed:NO
         beacons:beacons
         indoorLocation:nil
         verified:YES
         fraudPayload:fraudPayload
         expectedCountryCode:self.expectedCountryCode
         expectedStateCode:self.expectedStateCode
         expectedAddress:self.expectedAddress
         reason:reason
         transactionId:transactionId
         revealRiskId:revealRiskId
         useSecondaryVerifiedHost:useSecondaryVerifiedHost
         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events,
                             RadarUser *_Nullable user, NSArray<RadarGeofence *> *_Nullable nearbyGeofences,
                             RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
            if (status == RadarStatusSuccess && config != nil) {
                [RadarRevealRiskManager shared].revealRiskId = nil;
                [[RadarLocationManager sharedInstance] updateTrackingFromMeta:config.meta];
            }
            
            if (token) {
                self.lastToken = token;
                self.lastTokenSystemUptime = [NSProcessInfo processInfo].systemUptime;
                self.lastTokenBeacons = lastTokenBeacons;
            }
            
            [RadarUtilsDeprecated runOnMainThread:^{
                if (status != RadarStatusSuccess) {
                    [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];
                }
                
                if (completionHandler) {
                    completionHandler(status, token);
                }
                }];
            }];
        };
        return (.errorUnknown, nil)
    }

    public func startTrackingVerified(interval: TimeInterval) {
        // TODO: implement start tracking verified
    }

    func stopTrackingVerified() {
        // TODO: implement stop tracking verified
    }

    func updateMonitoringState() {
        // TODO: implement update monitoring state
    }

    func getVerifiedLocationToken(beacons: Bool, desiredAccuracy: RadarTrackingOptionsDesiredAccuracy) async -> RadarVerifiedLocationToken? {
        return nil
    }

    func clearVerifiedLocationToken() {
        sharingLock.lock()
        self.lastToken = nil
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

        RadarLogger.debug(
            "Last token \(tokenValid ? "valid" : "invalid") | lastToken.expiresIn = \(lastToken.expiresIn); lastTokenElapsed = \(timeElapsed); lastToken.passed = \(lastToken.passed); lastDistanceToStateBorder = \(lastDistanceToStateBorder)"
        )

        return tokenValid
    }

    func setExpectedJurisdiction(countryCode: String?, stateCode: String?) {
        sharingLock.lock()
        self.expectedStateCode = stateCode
        self.expectedCountryCode = countryCode
        sharingLock.unlock()
    }

    func isSharing() -> Bool {
        return fraudSDK?.isSharing() ?? false
    }

    func clearSharing() {
        fraudSDK?.clearSharing()
    }
}
