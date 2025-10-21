//
//  RadarSDKFraudProtocol.h
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarIPChangeCallback)(NSString *reason);
typedef void (^_Nullable RadarVerificationCompletionHandler)(NSString *_Nullable attestationString, NSString *_Nullable keyId, NSString *_Nullable attestationError);

@protocol RadarSDKFraudProtocol<NSObject>

+ (instancetype)sharedInstance;

/**
 * Detects fraud indicators for a given location
 * @param location The CLLocation to analyze for fraud
 */
- (NSString *)detectFraudWithLocation:(CLLocation *)location;

/**
 * Gets the kDeviceId for fraud detection
 * @return NSString containing the kDeviceId or nil if unavailable
 */
- (NSString *)kDeviceId;

/**
 * Starts IP monitoring with a callback for when IP changes are detected
 * @param callback Block to call when IP changes are detected
 */
- (void)startIPMonitoringWithCallback:(RadarIPChangeCallback)callback;

/**
 * Stops IP monitoring
 */
- (void)stopIPMonitoring;

/**
 * Gets device attestation for verification
 * @param nonce The nonce to use for attestation
 * @param completionHandler Block to call with attestation results
 */
- (void)getAttestationWithNonce:(NSString *)nonce completionHandler:(RadarVerificationCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
