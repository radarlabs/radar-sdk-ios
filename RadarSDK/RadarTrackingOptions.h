//
//  RadarTrackingOptions.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RadarTrackingOptionsDesiredAccuracy) {
    RadarTrackingOptionsDesiredAccuracyHigh,
    RadarTrackingOptionsDesiredAccuracyMedium,
    RadarTrackingOptionsDesiredAccuracyLow
};

typedef NS_ENUM(NSInteger, RadarTrackingOptionsReplay) {
    RadarTrackingOptionsReplayStops,
    RadarTrackingOptionsReplayNone
};

typedef NS_ENUM(NSInteger, RadarTrackingOptionsSync) {
    RadarTrackingOptionsSyncAll,
    RadarTrackingOptionsSyncStopsAndExits,
    RadarTrackingOptionsSyncNone
};

/**
 An options class used to configure background tracking.
 
 @see https://radar.io/documentation/sdk#ios-background
 */
@interface RadarTrackingOptions : NSObject

@property (nonatomic, assign) int desiredStoppedUpdateInterval;
@property (nonatomic, assign) int desiredMovingUpdateInterval;
@property (nonatomic, assign) int desiredSyncInterval;
@property (nonatomic, assign) RadarTrackingOptionsDesiredAccuracy desiredAccuracy;
@property (nonatomic, assign) int stopDuration;
@property (nonatomic, assign) int stopDistance;
@property (nullable, nonatomic, copy) NSDate *startTrackingAfter;
@property (nullable, nonatomic, copy) NSDate *stopTrackingAfter;
@property (nonatomic, assign) RadarTrackingOptionsReplay replay;
@property (nonatomic, assign) RadarTrackingOptionsSync sync;
@property (nonatomic, assign) BOOL showBlueBar;
@property (nonatomic, assign) BOOL useStoppedGeofence;
@property (nonatomic, assign) int stoppedGeofenceRadius;
@property (nonatomic, assign) BOOL useMovingGeofence;
@property (nonatomic, assign) int movingGeofenceRadius;
@property (nonatomic, assign) BOOL useVisits;
@property (nonatomic, assign) BOOL useSignificantLocationChanges;
@property (class, copy, readonly) RadarTrackingOptions *continuous;
@property (class, copy, readonly) RadarTrackingOptions *responsive;
@property (class, copy, readonly) RadarTrackingOptions *efficient;

+ (NSString *)stringForDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy;
+ (RadarTrackingOptionsDesiredAccuracy)desiredAccuracyForString:(NSString *)str;
+ (NSString *)stringForReplay:(RadarTrackingOptionsReplay)replay;
+ (RadarTrackingOptionsReplay)replayForString:(NSString *)str;
+ (NSString *)stringForSync:(RadarTrackingOptionsSync)sync;
+ (RadarTrackingOptionsSync)syncForString:(NSString *)str;
+ (RadarTrackingOptions * _Nonnull)trackingOptionsFromDictionary:(NSDictionary * _Nonnull)dictionary;
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
