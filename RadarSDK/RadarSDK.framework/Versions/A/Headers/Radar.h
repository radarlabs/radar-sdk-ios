//
//  Radar.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarUser.h"
#import "RadarGeofence.h"
#import "RadarEvent.h"

@protocol RadarDelegate;

/**
 * The status types for a request.
 */
typedef NS_ENUM(NSInteger, RadarStatus) {
    RadarStatusSuccess,
    RadarStatusErrorPublishableKey,
    RadarStatusErrorUserId,
    RadarStatusErrorPermissions,
    RadarStatusErrorLocation,
    RadarStatusErrorNetwork,
    RadarStatusErrorUnauthorized,
    RadarStatusErrorRateLimit,
    RadarStatusErrorPlaces,
    RadarStatusErrorServer,
    RadarStatusErrorUnknown
};

/**
 * The providers for Places data.
 */
typedef NS_ENUM(NSInteger, RadarPlacesProvider) {
    RadarPlacesProviderNone,
    RadarPlacesProviderFacebook
};

/**
 * The priorities for background tracking.
 */
typedef NS_ENUM(NSInteger, RadarPriority) {
    RadarPriorityResponsiveness,
    RadarPriorityEfficiency
};

@interface Radar : NSObject

/**
 * A block type, called when a location request completes. Receives the request status, the user's location, the events generated, if any, and the user.
 */
typedef void(^ _Nullable RadarCompletionHandler)(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user);

/**
 @abstract Initializes the Radar SDK.
 @warning You must call this method in application:didFinishLaunchingWithOptions: and pass your publishable API key.
 @param publishableKey Your publishable API key.
 **/
+ (void)initializeWithPublishableKey:(NSString * _Nonnull)publishableKey NS_SWIFT_NAME(initialize(publishableKey:));

/**
 @abstract Identifies the user.
 @warning You must call this method once before calling trackOnce: or startTracking.
 @param userId A stable unique ID for the user.
 **/
+ (void)setUserId:(NSString * _Nonnull)userId;

/**
 @abstract Reidentifies the user, changing their user ID without creating a new user.
 @warning To reidentify the user, you must call this method with the user's old stable unique ID, call setUserId: with the user's new stable unique ID, then track the user's location.
 @param oldUserId The old stable unique ID for the user. If nil, the previous ID will be cleared.
 **/
+ (void)reidentifyUserFromOldUserId:(NSString * _Nullable)oldUserId NS_SWIFT_NAME(reidentifyUser(oldUserId:));

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
 @abstract Sets an optional delegate for client-side event delivery.
 @param delegate A delegate for client-side event delivery. If nil, the previous delegate will be cleared.
 **/
+ (void)setDelegate:(id<RadarDelegate> _Nonnull)delegate;

/**
 @abstract Sets the provider for Places data.
 @param provider The provider for Places data.
 **/
+ (void)setPlacesProvider:(RadarPlacesProvider)provider;

/**
 @abstract Returns the app's location authorization status. A convenience method that calls authorizationStatus on CLLocationManager.
 @return A value indicating the app's location authorization status.
 **/
+ (CLAuthorizationStatus)authorizationStatus;

/**
 @abstract Requests permission to track the user's location in the foreground. A convenience method that calls requestWhenInUseAuthorization on the Radar SDK's instance of CLLocationManager.
 **/
+ (void)requestWhenInUseAuthorization;

/**
 @abstract Requests permission to track the user's location in the background. A convenience method that calls requestAlwaysAuthorization on the Radar SDK's instance of CLLocationManager.
 **/
+ (void)requestAlwaysAuthorization;

/**
 @abstract Tracks the user's location once in the foreground.
 @param completionHandler An optional completion handler.
 @warning Before calling this method, you must have called setUserId: once to identify the user, and the user's location authorization status must be kCLAuthorizationStatusAuthorizedWhenInUse or kCLAuthorizationStatusAuthorizedAlways.
 **/
+ (void)trackOnceWithCompletionHandler:(RadarCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(trackOnce(completionHandler:));

/**
 @abstract Sets the priority for background tracking.
 @param priority The priority for background tracking. RadarPriorityResponsiveness, the default, uses Radar stop detection and triggers more frequent wakeups for better responsiveness and reliability. RadarPriorityEfficiency uses iOS stop detection and triggers less frequent wakeups for better battery efficiency.
 @warning RadarPriorityResponsiveness requires the location background mode. Otherwise, RadarPriorityEfficiency is used.
 **/
+ (void)setTrackingPriority:(RadarPriority)priority;

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
 @abstract Accepts an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.
 @param eventId The ID of the event to accept.
 @param verifiedPlaceId For place entry events, the ID of the verified place. May be nil.
 **/
+ (void)acceptEventId:(NSString *_Nonnull)eventId withVerifiedPlaceId:(NSString *_Nullable)verifiedPlaceId NS_SWIFT_NAME(acceptEventId(_:verifiedPlaceId:));

/**
 @abstract Rejects an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.
 @param eventId The ID of the event to reject.
 **/
+ (void)rejectEventId:(NSString *_Nonnull)eventId NS_SWIFT_NAME(rejectEventId(_:));

/**
 @abstract Returns a boolean indicating whether the user's wi-fi is enabled. Location accuracy and reliability are greatly improved when wi-fi is enabled.
 @return A boolean indicating whether the user's wi-fi is enabled.
 **/
+ (BOOL)isWifiEnabled;

@end
