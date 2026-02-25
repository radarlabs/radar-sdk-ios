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

typedef void (^RadarFraudTrackVerifiedCallback)(NSDictionary<NSString *, id> *_Nullable result);

@protocol RadarSDKFraudProtocol<NSObject>

+ (instancetype)sharedInstance;

- (void)trackVerifiedWithOptions:(NSDictionary<NSString *, id> *)options completionHandler:(RadarFraudTrackVerifiedCallback)completionHandler;

@end

NS_ASSUME_NONNULL_END
