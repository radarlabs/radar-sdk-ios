//
//  RadarOfflineEventManager.h
//  RadarSDK
//
//  Created by Alan Charles on 4/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarTrackingOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarOfflineEventManager : NSObject

+ (void)reset;
+ (void)handleTrackFailure:(CLLocation *)location;
+ (RadarTrackingOptions * _Nullable)updateTrackingOptionsFor:(CLLocation *)location;
+ (void)setDebugLogger:(void (^ _Nullable)(NSString *message))logger;
+ (void)logDebug:(NSString *)message;


@end

NS_ASSUME_NONNULL_END
