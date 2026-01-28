//
//  RadarSDKFraudProtocol.h
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarIPChangeCallback)(NSString *reason);
typedef void (^RadarFraudPayloadCallback)(RadarStatus status, NSString *_Nullable payload);

@protocol RadarSDKFraudProtocol<NSObject>

+ (instancetype)sharedInstance;

- (void)getFraudPayloadWithOptions:(NSDictionary<NSString *, id> *)options completionHandler:(RadarFraudPayloadCallback)completionHandler;

- (void)startIPMonitoringWithCallback:(RadarIPChangeCallback)callback;

- (void)stopIPMonitoring;

@end

NS_ASSUME_NONNULL_END
