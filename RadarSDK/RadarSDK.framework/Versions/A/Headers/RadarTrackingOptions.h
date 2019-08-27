//
//  RadarTrackingOptions.h
//  RadarSDK
//
//  Created by Russell Cullen on 10/10/18.
//  Copyright © 2018 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An options class used to configure Radar tracking.
 */
@interface RadarTrackingOptions : NSObject

/**
 Determines how frequently location updates are requested on the client. Defaults to `RadarTrackingPriorityResponsiveness`.
 */
@property (nonatomic) RadarTrackingPriority priority;

/**
 Determines whether to replay offline location updates to the server. Defaults to `RadarTrackingOfflineReplayStopped`.
 */
@property (nonatomic) RadarTrackingOffline offline;

/**
 Determines which location updates to sync to the server. Defaults to `RadarSyncModeStateChanges`.
 */
@property (nonatomic) RadarTrackingSync sync;

/**
 Convenience block initializer for this class.
 */
+ (instancetype)makeWithBlock:(void (^)(RadarTrackingOptions *))updateBlock NS_SWIFT_NAME(make(updateBlock:));

@end

NS_ASSUME_NONNULL_END
