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

/**
 The status types for a request.

 - RadarStatusSuccess: Success
 - RadarStatusErrorPublishableKey: Publishable key is not set
 - RadarStatusErrorPermissions: Location permissions not granted
 - RadarStatusErrorLocation: Invalid location sent to server
 - RadarStatusErrorNetwork: Network failure
 - RadarStatusErrorUnauthorized: Unauthorized API call, check publishable key
 - RadarStatusErrorRateLimit: Radar rate limit was hit
 - RadarStatusErrorServer: Radar server error
 - RadarStatusErrorUnknown: Unknown error
 */
typedef NS_ENUM(NSInteger, RadarStatus) {
    RadarStatusSuccess,
    RadarStatusErrorPublishableKey,
    RadarStatusErrorPermissions,
    RadarStatusErrorLocation,
    RadarStatusErrorNetwork,
    RadarStatusErrorUnauthorized,
    RadarStatusErrorRateLimit,
    RadarStatusErrorServer,
    RadarStatusErrorUnknown
};

/**
 The providers for Places data.

 - RadarPlacesProviderNone: No places provider
 - RadarPlacesProviderFacebook: Facebook Places
 */
typedef NS_ENUM(NSInteger, RadarPlacesProvider) {
    RadarPlacesProviderNone,
    RadarPlacesProviderFacebook
};

/**
 The Radar SDK
 
 For detailed documentation, look below or on the web - https://radar.io/documentation/sdk
 */
@interface Radar : NSObject

/**
 * A block type, called when a location request completes. Receives the request status, the user's location, the events generated, if any, and the user.
 */
typedef void(^_Nullable RadarCompletionHandler)(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user);

/**
 @abstract Initializes the Radar SDK.
 @warning You must call this method in application:didFinishLaunchingWithOptions: and pass your publishable API key.
 @param publishableKey Your publishable API key.
 **/
+ (void)initializeWithPublishableKey:(NSString * _Nonnull)publishableKey NS_SWIFT_NAME(initialize(publishableKey:));

/**
 @abstract Identifies the user when logged in.
 @warning Until you identify the user, Radar will automatically identify the user by deviceId (IDFV).
 @param userId A stable unique ID for the user.
 **/
+ (void)setUserId:(NSString * _Nullable)userId;

/**
 @abstract Sets an optional description for the user, displayed in the dashboard.
 @param description A description for the user. If nil, the previous description will be cleared.
 **/
+ (void)setDescription:(NSString * _Nullable)description;

/**
 @abstract Sets an optional set of custom key-value pairs for the user.
 @param metadata A set of custom key-value pairs for the user. Must have 16 or fewer keys and values of type string, boolean, or number. If nil, the previous metadata will be cleared.
 **/
+ (void)setMetadata:(NSDictionary * _Nullable)metadata;

/**
 @abstract Sets the provider for Places data.
 @param provider The provider for Places data.
 **/
+ (void)setPlacesProvider:(RadarPlacesProvider)provider;

/**
 @abstract Tracks the user's location once in the foreground.
 @param completionHandler An optional completion handler.
 @warning Before calling this method, you must have called setUserId: once to identify the user, and the user's location authorization status must be kCLAuthorizationStatusAuthorizedWhenInUse or kCLAuthorizationStatusAuthorizedAlways.
 **/
+ (void)trackOnceWithCompletionHandler:(RadarCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(trackOnce(completionHandler:));

/**
 @abstract Starts tracking the user's location in the background.
 @warning Before calling this method, you must have called setUserId: once to identify the user, and the user's location authorization status must be kCLAuthorizationStatusAuthorizedAlways.
 **/
+ (void)startTracking;

/**
 @abstract Stops tracking the user's location in the background.
 **/
+ (void)stopTracking;

/**
 @abstract Returns a boolean indicating whether the user's location is being tracked in the background.
 @return A boolean indicating whether the user's location is being tracked in the background.
 **/
+ (BOOL)isTracking;

/**
 @abstract Manually updates the user's location.
 @param location A location for the user. Must have a valid latitude, longitude, and accuracy.
 @param completionHandler An optional completion handler.
 @warning Before calling this method, you must have called setUserId: once to identify the user.
 **/
+ (void)updateLocation:(CLLocation * _Nonnull)location withCompletionHandler:(RadarCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(updateLocation(_:completionHandler:));

/**
 Sets an optional delegate for client-side event delivery.

 @param delegate A delegate for client-side event delivery. If nil, the previous delegate will be cleared.
 
 @note Radar keeps a weak reference to the given delegate so there's usually no need to explicitly clear it.
 */
+ (void)setDelegate:(nullable id <RadarDelegate>)delegate;

/**
 Accepts an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.

 @param eventId The ID of the event to accept.
 @param verifiedPlaceId For place entry events, the ID of the verified place. May be nil.
 */
+ (void)acceptEventId:(NSString *_Nonnull)eventId withVerifiedPlaceId:(NSString *_Nullable)verifiedPlaceId NS_SWIFT_NAME(acceptEventId(_:verifiedPlaceId:));

/**
Rejects an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.

 @param eventId The ID of the event to reject.
 */
+ (void)rejectEventId:(NSString *_Nonnull)eventId NS_SWIFT_NAME(rejectEventId(_:));

@end
