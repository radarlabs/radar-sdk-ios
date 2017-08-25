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
#import "RadarPlace.h"

@interface RadarEvent : NSObject

/**
 * The types for events.
 */
typedef NS_ENUM(NSInteger, RadarEventType) {
    RadarEventTypeUnknown NS_SWIFT_NAME(unknown),
    RadarEventTypeUserEnteredGeofence NS_SWIFT_NAME(userEnteredGeofence),
    RadarEventTypeUserExitedGeofence NS_SWIFT_NAME(userExitedGeofence),
    RadarEventTypeUserEnteredHome NS_SWIFT_NAME(userEnteredHome),
    RadarEventTypeUserExitedHome NS_SWIFT_NAME(userExitedHome),
    RadarEventTypeUserEnteredOffice NS_SWIFT_NAME(userEnteredOffice),
    RadarEventTypeUserExitedOffice NS_SWIFT_NAME(userExitedOffice),
    RadarEventTypeUserStartedTraveling NS_SWIFT_NAME(userStartedTraveling),
    RadarEventTypeUserStoppedTraveling NS_SWIFT_NAME(userStoppedTraveling),
    RadarEventTypeUserEnteredPlace NS_SWIFT_NAME(userEnteredPlace),
    RadarEventTypeUserExitedPlace NS_SWIFT_NAME(userExitedPlace),
};

/**
 * The confidence levels for events.
 */
typedef NS_ENUM(NSInteger, RadarEventConfidence) {
    RadarEventConfidenceNone NS_SWIFT_NAME(none) = 0,
    RadarEventConfidenceLow NS_SWIFT_NAME(low) = 1,
    RadarEventConfidenceMedium NS_SWIFT_NAME(medium) = 2,
    RadarEventConfidenceHigh NS_SWIFT_NAME(high) = 3
};

/**
 * The verification types for events.
 */
typedef NS_ENUM(NSInteger, RadarEventVerification) {
    RadarEventVerificationAccept NS_SWIFT_NAME(accept) = 1,
    RadarEventVerificationUnverify NS_SWIFT_NAME(unverify) = 0,
    RadarEventVerificationReject NS_SWIFT_NAME(reject) = -1
};

/**
 * @abstract The unique ID for the event, provided by Radar.
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
 * @abstract The geofence for which the event was generated. May be nil for non-geofence events.
 */
@property (nullable, strong, nonatomic, readonly) RadarGeofence *geofence;

/**
 * @abstract The place for which the event was generated. May be nil for non-place events.
 */
@property (nullable, strong, nonatomic, readonly) RadarPlace *place;

/**
 * @abstract For place entry events, alternate place candidates. May be nil for non-place events.
 */
@property (nullable, strong, nonatomic, readonly) NSArray<RadarPlace *> *alternatePlaces;

/**
 * @abstract For accepted place entry events, the verified place. May be nil for non-place events.
 */
@property (nullable, strong, nonatomic, readonly) RadarPlace *verifiedPlace;

/**
 * @abstract The verification of the event.
 */
@property (assign, nonatomic, readonly) RadarEventVerification verification;

/**
 * @abstract The confidence level of the event.
 */
@property (assign, nonatomic, readonly) RadarEventConfidence confidence;

/**
 * @abstract The duration between entry and exit events, in minutes, for exit events. 0 for entry events.
 */
@property (assign, nonatomic, readonly) float duration;

@end
