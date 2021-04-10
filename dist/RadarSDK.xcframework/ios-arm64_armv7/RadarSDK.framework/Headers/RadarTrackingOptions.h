//
//  RadarTrackingOptions.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The location accuracy options.
 */
typedef NS_ENUM(NSInteger, RadarTrackingOptionsDesiredAccuracy) {
    /// Uses `kCLLocationAccuracyBest`
    RadarTrackingOptionsDesiredAccuracyHigh,
    /// Uses `kCLLocationAccuracyHundredMeters`, the default
    RadarTrackingOptionsDesiredAccuracyMedium,
    /// Uses `kCLLocationAccuracyKilometer`
    RadarTrackingOptionsDesiredAccuracyLow
};

/**
 The replay options for failed location updates.
 */
typedef NS_ENUM(NSInteger, RadarTrackingOptionsReplay) {
    /// Replays failed stops
    RadarTrackingOptionsReplayStops,
    /// Replays no failed location updates
    RadarTrackingOptionsReplayNone
};

/**
 The sync options for location updates.
 */
typedef NS_ENUM(NSInteger, RadarTrackingOptionsSync) {
    /// Syncs all location updates to the server
    RadarTrackingOptionsSyncAll,
    /// Syncs only stops and exits to the server
    RadarTrackingOptionsSyncStopsAndExits,
    /// Syncs no location updates to the server
    RadarTrackingOptionsSyncNone
};

/**
 An options class used to configure background tracking.

 @see https://radar.io/documentation/sdk/ios
 */
@interface RadarTrackingOptions : NSObject

/**
 Determines the desired location update interval in seconds when stopped. Use 0 to shut down when stopped.

 @warning Note that location updates may be delayed significantly by Low Power Mode, or if the device has connectivity issues, low battery, or wi-fi disabled.
 */
@property (nonatomic, assign) int desiredStoppedUpdateInterval;

/**
 Determines the desired location update interval in seconds when moving.

 @warning Note that location updates may be delayed significantly by Low Power Mode, or if the device has connectivity issues, low battery, or wi-fi disabled.
 */
@property (nonatomic, assign) int desiredMovingUpdateInterval;

/**
 Determines the desired sync interval in seconds.
 */
@property (nonatomic, assign) int desiredSyncInterval;

/**
 Determines the desired accuracy of location updates.
 */
@property (nonatomic, assign) RadarTrackingOptionsDesiredAccuracy desiredAccuracy;

/**
 With `stopDistance`, determines the duration in seconds after which the device is considered stopped.
 */
@property (nonatomic, assign) int stopDuration;

/**
 With `stopDuration`, determines the distance in meters within which the device is considered stopped.
 */
@property (nonatomic, assign) int stopDistance;

/**
 Determines when to start tracking. Use `nil` to start tracking when `startTracking` is called.
 */
@property (nullable, nonatomic, copy) NSDate *startTrackingAfter;

/**
 Determines when to stop tracking. Use `nil` to track until `stopTracking` is called.
 */
@property (nullable, nonatomic, copy) NSDate *stopTrackingAfter;

/**
 Determines which failed location updates to replay to the server.
 */
@property (nonatomic, assign) RadarTrackingOptionsReplay replay;

/**
 Determines which location updates to sync to the server.
 */
@property (nonatomic, assign) RadarTrackingOptionsSync sync;

/**
 Determines whether the flashing blue status bar is shown when tracking.

 @see https://developer.apple.com/documentation/corelocation/cllocationmanager/2923541-showsbackgroundlocationindicator
 */
@property (nonatomic, assign) BOOL showBlueBar;

/**
 Determines whether to use the iOS region monitoring service (geofencing) to create a client geofence around the device's current location when stopped.

 @see https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions
 */
@property (nonatomic, assign) BOOL useStoppedGeofence;

/**
 Determines the radius in meters of the client geofence around the device's current location when stopped.
 */
@property (nonatomic, assign) int stoppedGeofenceRadius;

/**
 Determines whether to use the iOS region monitoring service (geofencing) to create a client geofence around the device's current location when moving.

 @see https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions
 */
@property (nonatomic, assign) BOOL useMovingGeofence;

/**
 Determines the radius in meters of the client geofence around the device's current location when moving.
 */
@property (nonatomic, assign) int movingGeofenceRadius;

/**
 Determines whether to sync nearby geofences from the server to the client to improve responsiveness.
 */
@property (nonatomic, assign) BOOL syncGeofences;

/**
 Determines whether to use the iOS visit monitoring service.

 @see https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_visits_location_service
 */
@property (nonatomic, assign) BOOL useVisits;

/**
 Determines whether to use the iOS significant location change service.

 @see https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_significant-change_location_service
 */
@property (nonatomic, assign) BOOL useSignificantLocationChanges;

/**
 Determines whether to monitor beacons.
 */
@property (nonatomic, assign) BOOL beacons;

/**
 A preset that updates about every 30 seconds and syncs all locations to the server. High battery usage. Shows the flashing blue status bar when tracking.

 @see https://developer.apple.com/documentation/corelocation/cllocationmanager/2923541-showsbackgroundlocationindicator
 */
@property (class, copy, readonly) RadarTrackingOptions *continuous;

/**
 A preset that updates about every 2.5 minutes when moving, shuts down when stopped, and only syncs stops and exits to the server. Requires the `location`
 background mode. Must move at least 200 meters to start moving again after a stop. Low battery usage.

 Note that location updates may be delayed significantly by Low Power Mode, or if the device has connectivity issues, low battery, or wi-fi disabled.
 */
@property (class, copy, readonly) RadarTrackingOptions *responsive;

/**
 A preset that uses the iOS visit monitoring service to update only on stops and exits. Must move a significant distance to start moving again after a stop.
 Lowest battery usage. Recommended.

 Note that location updates may be delayed significantly by Low Power Mode, or if the device has connectivity issues, low battery, or wi-fi disabled.

 @see https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_visits_location_service
 */
@property (class, copy, readonly) RadarTrackingOptions *efficient;

+ (NSString *)stringForDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy;
+ (RadarTrackingOptionsDesiredAccuracy)desiredAccuracyForString:(NSString *)str;
+ (NSString *)stringForReplay:(RadarTrackingOptionsReplay)replay;
+ (RadarTrackingOptionsReplay)replayForString:(NSString *)str;
+ (NSString *)stringForSync:(RadarTrackingOptionsSync)sync;
+ (RadarTrackingOptionsSync)syncForString:(NSString *)str;
+ (RadarTrackingOptions *_Nonnull)trackingOptionsFromDictionary:(NSDictionary *_Nonnull)dictionary;
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
