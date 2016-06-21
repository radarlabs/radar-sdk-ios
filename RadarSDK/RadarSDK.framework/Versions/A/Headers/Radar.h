//
//  Radar.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Radar : NSObject

/**
 @abstract Initializes the Radar SDK.
 @warning You must call this method in application:didFinishLaunchingWithOptions: and pass your API key.
 @param key API key (required)
 **/
+ (void)init:(NSString * _Nonnull)key;

/**
 @abstract Prompts the user to authorize location access.
 **/
+ (void)authorize;

/**
 @abstract Starts location tracking for the user.
 @param userId Unique ID for the user (required)
 @param description Description for the user (optional)
 @warning If you have not called authorize before calling this method, it will be called automatically when you call this method.
 **/
+ (void)startTracking:(NSString * _Nonnull)userId description:(NSString * _Nullable)description;

/**
 @abstract Stops location tracking for the user.
 **/
+ (void)stopTracking;

@end
