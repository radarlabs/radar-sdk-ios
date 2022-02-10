//
//  RadarEvent.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarGeofence.h"
#import "RadarPlace.h"
#import "RadarRegion.h"
#import "RadarUser.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

/**
 Represents a change in user state.
 */
@interface RadarEvent : NSObject

/**
 The types for events.
 */
typedef NS_ENUM(NSInteger, RadarEventType) {
    /// Unknown
    RadarEventTypeUnknown NS_SWIFT_NAME(unknown),
    /// `user.entered_geofence`
    RadarEventTypeUserEnteredGeofence NS_SWIFT_NAME(userEnteredGeofence),
    /// `user.exited_geofence`
    RadarEventTypeUserExitedGeofence NS_SWIFT_NAME(userExitedGeofence),
    /// `user.entered_home`
    RadarEventTypeUserEnteredHome NS_SWIFT_NAME(userEnteredHome),
    /// `user.exited_home`
    RadarEventTypeUserExitedHome NS_SWIFT_NAME(userExitedHome),
    /// `user.entered_office`
    RadarEventTypeUserEnteredOffice NS_SWIFT_NAME(userEnteredOffice),
    /// `user.exited_office`
    RadarEventTypeUserExitedOffice NS_SWIFT_NAME(userExitedOffice),
    /// `user.started_traveling`
    RadarEventTypeUserStartedTraveling NS_SWIFT_NAME(userStartedTraveling),
    /// `user.stopped_traveling`
    RadarEventTypeUserStoppedTraveling NS_SWIFT_NAME(userStoppedTraveling),
    /// `user.entered_place`
    RadarEventTypeUserEnteredPlace NS_SWIFT_NAME(userEnteredPlace),
    /// `user.exited_place`
    RadarEventTypeUserExitedPlace NS_SWIFT_NAME(userExitedPlace),
    /// `user.nearby_place_chain`
    RadarEventTypeUserNearbyPlaceChain NS_SWIFT_NAME(userNearbyPlaceChain),
    /// `user.entered_region_country`
    RadarEventTypeUserEnteredRegionCountry NS_SWIFT_NAME(userEnteredRegionCountry),
    /// `user.exited_region_country`
    RadarEventTypeUserExitedRegionCountry NS_SWIFT_NAME(userExitedRegionCountry),
    /// `user.entered_region_state`
    RadarEventTypeUserEnteredRegionState NS_SWIFT_NAME(userEnteredRegionState),
    /// `user.exited_region_state`
    RadarEventTypeUserExitedRegionState NS_SWIFT_NAME(userExitedRegionState),
    /// `user.entered_region_dma`
    RadarEventTypeUserEnteredRegionDMA NS_SWIFT_NAME(userEnteredRegionDMA),
    /// `user.exited_region_dma`
    RadarEventTypeUserExitedRegionDMA NS_SWIFT_NAME(userExitedRegionDMA),
    /// `user.started_commuting`
    RadarEventTypeUserStartedCommuting NS_SWIFT_NAME(userStartedCommuting),
    /// `user.stopped_commuting`
    RadarEventTypeUserStoppedCommuting NS_SWIFT_NAME(userStoppedCommuting),
    /// `user.started_trip`
    RadarEventTypeUserStartedTrip NS_SWIFT_NAME(userStartedTrip),
    /// `user.updated_trip`
    RadarEventTypeUserUpdatedTrip NS_SWIFT_NAME(userUpdatedTrip),
    /// `user.approaching_trip_destination`
    RadarEventTypeUserApproachingTripDestination NS_SWIFT_NAME(userApproachingTripDestination),
    /// `user.arrived_at_trip_destination`
    RadarEventTypeUserArrivedAtTripDestination NS_SWIFT_NAME(userArrivedAtTripDestination),
    /// `user.stopped_trip`
    RadarEventTypeUserStoppedTrip NS_SWIFT_NAME(userStoppedTrip),
    /// `user.entered_beacon`
    RadarEventTypeUserEnteredBeacon NS_SWIFT_NAME(userEnteredBeacon),
    /// `user.exited_beacon`
    RadarEventTypeUserExitedBeacon NS_SWIFT_NAME(userExitedBeacon),
    /// `user.entered_region_postal_code`
    RadarEventTypeUserEnteredRegionPostalCode NS_SWIFT_NAME(userEnteredRegionPostalCode),
    /// `user.exited_region_postal_code`
    RadarEventTypeUserExitedRegionPostalCode NS_SWIFT_NAME(userExitedRegionPostalCode)
};

/**
 The confidence levels for events.
 */
typedef NS_ENUM(NSInteger, RadarEventConfidence) {
    /// Unknown confidence
    RadarEventConfidenceNone NS_SWIFT_NAME(none) = 0,
    /// Low confidence
    RadarEventConfidenceLow NS_SWIFT_NAME(low) = 1,
    /// Medium confidence
    RadarEventConfidenceMedium NS_SWIFT_NAME(medium) = 2,
    /// High confidence
    RadarEventConfidenceHigh NS_SWIFT_NAME(high) = 3
};

/**
 The verification types for events.
 */
typedef NS_ENUM(NSInteger, RadarEventVerification) {
    /// Accept event
    RadarEventVerificationAccept NS_SWIFT_NAME(accept) = 1,
    /// Unverify event
    RadarEventVerificationUnverify NS_SWIFT_NAME(unverify) = 0,
    /// Reject event
    RadarEventVerificationReject NS_SWIFT_NAME(reject) = -1
};

/**
 The Radar ID of the event.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 The datetime when the event occurred on the device.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *createdAt;

/**
 The datetime when the event was created on the server.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *actualCreatedAt;

/**
 A boolean indicating whether the event was generated with your live API key.
 */
@property (assign, nonatomic, readonly) BOOL live;

/**
 The type of the event.
 */
@property (assign, nonatomic, readonly) RadarEventType type;

/**
 The geofence for which the event was generated. May be `nil` for non-geofence events.
 */
@property (nullable, strong, nonatomic, readonly) RadarGeofence *geofence;

/**
 The place for which the event was generated. May be `nil` for non-place events.
 */
@property (nullable, strong, nonatomic, readonly) RadarPlace *place;

/**
 The region for which the event was generated. May be `null` for non-region events.
 */
@property (nullable, strong, nonatomic, readonly) RadarRegion *region;

/**
 The beacon for which the event was generated. May be `nil` for non-beacon events.
 */
@property (nullable, strong, nonatomic, readonly) RadarBeacon *beacon;

/**
 The trip for which the event was generated. May be `nil` for non-trip events.
 */
@property (nullable, strong, nonatomic, readonly) RadarTrip *trip;

/**
 For place entry events, alternate place candidates. May be `nil` for non-place events.
 */
@property (nullable, strong, nonatomic, readonly) NSArray<RadarPlace *> *alternatePlaces;

/**
 For accepted place entry events, the verified place. May be `nil` for non-place events or unverified events.
 */
@property (nullable, strong, nonatomic, readonly) RadarPlace *verifiedPlace;

/**
 The verification of the event.
 */
@property (assign, nonatomic, readonly) RadarEventVerification verification;

/**
 The confidence level of the event.
 */
@property (assign, nonatomic, readonly) RadarEventConfidence confidence;

/**
 The duration between entry and exit events, in minutes, for exit events. 0 for entry events.
 */
@property (assign, nonatomic, readonly) float duration;

/**
 The location of the event.
 */
@property (nonnull, strong, nonatomic, readonly) CLLocation *location;

+ (NSString *_Nullable)stringForType:(RadarEventType)type;
+ (NSArray<NSDictionary *> *_Nullable)arrayForEvents:(NSArray<RadarEvent *> *_Nullable)events;
- (NSDictionary *_Nonnull)dictionaryValue;

@end
