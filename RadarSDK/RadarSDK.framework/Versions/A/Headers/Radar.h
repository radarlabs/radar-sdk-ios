//
//  Radar.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface Radar : NSObject

/**
 @abstract Initializes the Radar SDK.
 @warning You must call this method in application:didFinishLaunchingWithOptions: and pass your API key.
 @param key API key (required)
 **/
+ (void)initWithKey:(NSString * _Nonnull)key;

/**
 @abstract Returns the app's location authorization status.
 @return A value indicating the app's location authorization status.
 **/
+ (CLAuthorizationStatus)authorizationStatus;

/**
 @abstract Requests permission to track the user's location in the foreground. Calls requestWhenInUseAuthorization on the Radar SDK's instance of CLLocationManager.
 **/
+ (void)requestWhenInUseAuthorization;

/**
 @abstract Requests permission to track the user's location in the background. Calls requestAlwaysAuthorization on the Radar SDK's instance of CLLocationManager.
 **/
+ (void)requestAlwaysAuthorization;

/**
 @abstract Tracks the user's location once in the foreground.
 @param userId Unique ID for the user (required)
 @param description Description for the user (optional)
 @warning Before calling this method, the user's location authorization status must be kCLAuthorizationStatusAuthorizedWhenInUse or kCLAuthorizationStatusAuthorizedAlways.
 **/
+ (void)trackOnceWithUserId:(NSString * _Nonnull)userId description:(NSString * _Nullable)description;

/**
 @abstract Starts tracking the user's location in the background.
 @param userId Unique ID for the user (required)
 @param description Description for the user (optional)
 @warning Before calling this method, the user's location authorization status must be kCLAuthorizationStatusAuthorizedAlways.
 **/
+ (void)startTrackingWithUserId:(NSString * _Nonnull)userId description:(NSString * _Nullable)description;

/**
 @abstract Stops tracking location in the background.
 **/
+ (void)stopTracking;

/**
 @abstract Returns a boolean indicating whether the user's location is being tracked in the background.
 @return A boolean indicating whether the user's location is being tracked in the background.
 **/
+ (BOOL)isTracking;

@end
