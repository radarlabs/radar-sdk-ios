//
//  RadarNotificationHelper.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarNotificationHelper : NSObject

+ (void)showNotificationsForEvents:(NSArray<RadarEvent *> *)events;

+ (void)swizzleNotificationCenterDelegate;

@end

NS_ASSUME_NONNULL_END
