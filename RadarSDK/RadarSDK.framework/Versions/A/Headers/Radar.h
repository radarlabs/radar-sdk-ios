//
//  Radar.h
//  RadarSDK
//
//  Copyright © 2018 Radar. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RadarEvent.h"
#import "RadarGeofence.h"
#import "RadarUser.h"

@protocol RadarDelegate;
@class RadarTrackingOptions;

/**
 The status types for a request.
 
 @see https://radar.io/documentation/sdk#ios-foreground
 */
typedef NS_ENUM(NSInteger, RadarStatus) {
    /// The request succeeded
    RadarStatusSuccess,
    /// The SDK was not initialized with a publishable API key
    RadarStatusErrorPublishableKey,
    /// The app's location authorization status is not `kCLAuthorizationStatusAuthorizedWhenInUse` or `kCLAuthorizationStatusAuthorizedAlways`
    RadarStatusErrorPermissions,
    /// Location services were unavailable, or the location request timed out.
    RadarStatusErrorLocation,
    /// The network was unavailable, or the network connection timed out
    RadarStatusErrorNetwork,
    /// The publishable API key is invalid
    RadarStatusErrorUnauthorized,
    /// Exceeded rate limit of 1 request per second per user or 60 requests per hour per user
    RadarStatusErrorRateLimit,
    /// An internal server error occurred
    RadarStatusErrorServer,
    /// An unknown error occurred
    RadarStatusErrorUnknown
};

/**
 The providers for Places data.
 
 @see https://radar.io/documentation/sdk#ios-places
 */
typedef NS_ENUM(NSInteger, RadarPlacesProvider) {
    /// No places provider
    RadarPlacesProviderNone,
    /// Facebook Places
    RadarPlacesProviderFacebook
};

/**
 The offline modes for tracking.
 
 @see https://radar.io/documentation/sdk#ios-background
 */
typedef NS_ENUM(NSInteger, RadarTrackingOffline) {
    /// Replays no location updates
    RadarTrackingOfflineReplayOff = -1,
    /// The default, replays stopped location updates
    RadarTrackingOfflineReplayStopped = 1
};

/**
 The sync modes for tracking.
 
 @see https://radar.io/documentation/sdk#ios-background
 */
typedef NS_ENUM(NSInteger, RadarTrackingSync) {
    /// Syncs all location updates
    RadarTrackingSyncAll = -1,
    /// The default, syncs only location updates that could generate events
    RadarTrackingSyncPossibleStateChanges = 1
};

/**
 The top-level class used to interact with the Radar SDK. For more information, see https://radar.io/documentation/sdk
.
 
 @see https://radar.io/documentation/sdk
 */
@interface Radar : NSObject

/**
 Called when a request succeeds, fails, or times out. Receives the request status and, if successful, the user's location, the events generated, and the user.
 
 @see https://radar.io/documentation/sdk#ios-foreground
 */
typedef void(^_Nullable RadarCompletionHandler)(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user);

/**
 Initializes the Radar SDK.
 
 @warning Call this method from the main thread in your `AppDelegate` class before calling any other Radar methods.
 
 @param publishableKey Your publishable API key.
 
 @see https://radar.io/documentation/sdk#ios-initialize
 **/
+ (void)initializeWithPublishableKey:(NSString * _Nonnull)publishableKey NS_SWIFT_NAME(initialize(publishableKey:));

/**
 Identifies the user when logged in.
 
 @note Until you identify the user, Radar will automatically identify the user by `deviceId` (IDFV).
 
 @param userId A stable unique ID for the user.
 
 @see https://radar.io/documentation/sdk#ios-identify
 **/
+ (void)setUserId:(NSString * _Nullable)userId;

/**
 Sets an optional description for the user, displayed in the dashboard.
 
 @param description A description for the user. If `nil`, the previous description will be cleared.
 
 @see https://radar.io/documentation/sdk#ios-identify
 **/
+ (void)setDescription:(NSString * _Nullable)description;

/**
 Sets an optional set of custom key-value pairs for the user.
 
 @param metadata A set of custom key-value pairs for the user. Must have 16 or fewer keys and values of type string, boolean, or number. If `nil`, the previous metadata will be cleared.
 **/
+ (void)setMetadata:(NSDictionary * _Nullable)metadata;

/**
 Sets the provider for Places data.
 
 @param provider The provider for Places data.
 
 @see https://radar.io/documentation/sdk#ios-places
 **/
+ (void)setPlacesProvider:(RadarPlacesProvider)provider;

/**
 Tracks the user's location once in the foreground.
 
 @warning Before calling this method, the user's location authorization status must be `kCLAuthorizationStatusAuthorizedWhenInUse` or `kCLAuthorizationStatusAuthorizedAlways`.
 
 @param completionHandler An optional completion handler.
 
 @see https://radar.io/documentation/sdk#ios-foreground
 **/
+ (void)trackOnceWithCompletionHandler:(RadarCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(trackOnce(completionHandler:));

/**
 Starts tracking the user's location in the background.
 
 @warning Before calling this method, the user's location authorization status must be `kCLAuthorizationStatusAuthorizedAlways`.
 
 @see https://radar.io/documentation/sdk#ios-background
 **/
+ (void)startTracking;

/**
 Starts tracking the user's location in the background with configurable tracking options.
 
 @warning Before calling this method, the user's location authorization status must be `kCLAuthorizationStatusAuthorizedAlways`.
 
 @see https://radar.io/documentation/sdk#ios-background
 **/
+ (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions NS_SWIFT_NAME(startTracking(trackingOptions:));

/**
 Stops tracking the user's location in the background.
 
 @see https://radar.io/documentation/sdk#ios-background
 **/
+ (void)stopTracking;

/**
 Returns a boolean indicating whether tracking has been started.
 
 @return A boolean indicating whether tracking has been started.
 **/
+ (BOOL)isTracking;

/**
 Manually updates the user's location.
 
 @warning Be careful not to exceed the rate limit of 1 request per second per user or 60 requests per hour per user.
 
 @param location A location for the user.
 @param completionHandler An optional completion handler.
 
 @see https://radar.io/documentation/sdk#ios-manual
 **/
+ (void)updateLocation:(CLLocation * _Nonnull)location withCompletionHandler:(RadarCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(updateLocation(_:completionHandler:));

/**
 Sets an optional delegate for client-side delivery of server-persisted events and location updates.

 @param delegate A delegate for client-side delivery of server-persisted events and location updates. If `nil`, the previous delegate will be cleared.
 
 @see https://radar.io/documentation/sdk#ios-background
 */
+ (void)setDelegate:(nullable id <RadarDelegate>)delegate;

/**
 Accepts an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.

 @param eventId The ID of the event to accept.
 @param verifiedPlaceId For place entry events, the ID of the verified place. May be `nil`.
 
 @see https://radar.io/documentation/sdk#ios-verify
 */
+ (void)acceptEventId:(NSString *_Nonnull)eventId withVerifiedPlaceId:(NSString *_Nullable)verifiedPlaceId NS_SWIFT_NAME(acceptEventId(_:verifiedPlaceId:));

/**
Rejects an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.

 @param eventId The ID of the event to reject.
 
 @see https://radar.io/documentation/sdk#ios-verify
 */
+ (void)rejectEventId:(NSString *_Nonnull)eventId NS_SWIFT_NAME(rejectEventId(_:));

+ (void)performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler NS_SWIFT_NAME(performFetchWithCompletionHandler(_:));

@end
