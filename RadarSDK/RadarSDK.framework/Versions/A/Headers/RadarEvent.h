//
//  RadarEvent.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarUser.h"
#import "RadarGeofence.h"

@interface RadarEvent : NSObject

typedef NS_ENUM(NSInteger, RadarEventType) {
    UserEnteredGeofence = 1,
    UserExitedGeofence
};

- (instancetype _Nullable)initWithId:(NSString * _Nonnull)_id createdAt:(NSDate * _Nonnull)createdAt live:(BOOL)live type:(RadarEventType)type user:(RadarUser * _Nonnull)user geofence:(RadarGeofence * _Nonnull)geofence location:(CLLocation * _Nonnull)location duration:(float)duration;

/**
 * @abstract The unique ID for the event provided by Radar.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 * @abstract The datetime when the event was created.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *createdAt;

/**
 * @abstract A boolean indicating whether the event was generated for a user created with your live API key.
 */
@property (assign, nonatomic, readonly) BOOL live;

/**
 * @abstract The type of event.
 */
@property (assign, nonatomic, readonly) RadarEventType type;

/**
 * @abstract The user for which the event was generated.
 */
@property (nonnull, strong, nonatomic, readonly) RadarUser *user;

/**
 * @abstract The geofence for which the event was generated.
 */
@property (nonnull, strong, nonatomic, readonly) RadarGeofence *geofence;

/**
 * @abstract The location of the user at the time of the event.
 */
@property (nonnull, copy, nonatomic, readonly) CLLocation *location;

/**
 * @abstract The duration between entry and exit events, in minutes, for exit events. 0 for entry events.
 */
@property (assign, nonatomic, readonly) float duration;

@end
