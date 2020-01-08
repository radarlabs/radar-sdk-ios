//
//  Radar.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "RadarAddress.h"
#import "RadarEvent.h"
#import "RadarRegion.h"
#import "RadarTrackingOptions.h"
#import "RadarUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarDelegate;

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
    /// Exceeded rate limit
    RadarStatusErrorRateLimit,
    /// An internal server error occurred
    RadarStatusErrorServer,
    /// An unknown error occurred
    RadarStatusErrorUnknown
};

/**
 The sources for location updates.
 */
typedef NS_ENUM(NSInteger, RadarLocationSource) {
    /// Foreground
    RadarLocationSourceForegroundLocation,
    /// Background
    RadarLocationSourceBackgroundLocation,
    /// Manual
    RadarLocationSourceManualLocation,
    /// Visit arrival
    RadarLocationSourceVisitArrival,
    /// Visit departure
    RadarLocationSourceVisitDeparture,
    /// Geofence enter
    RadarLocationSourceGeofenceEnter,
    /// Geofence exit
    RadarLocationSourceGeofenceExit,
    /// Unknown
    RadarLocationSourceUnknown
};

/**
 The levels for debug logs.
 */
typedef NS_ENUM(NSInteger, RadarLogLevel) {
    /// None
    RadarLogLevelNone = 0,
    /// Error
    RadarLogLevelError = 1,
    /// Warning
    RadarLogLevelWarning = 2,
    /// Info
    RadarLogLevelInfo = 3,
    /// Debug
    RadarLogLevelDebug = 4
};

/**
 Called when a location request succeeds, fails, or times out. Receives the request status and, if successful, the location.
 
 @see https://radar.io/documentation/sdk#ios-foreground
 */
typedef void(^ _Nullable RadarLocationCompletionHandler)(RadarStatus status, CLLocation * _Nullable location, BOOL stopped);

/**
 Called when a track request succeeds, fails, or times out. Receives the request status and, if successful, the user's location, an array of the events generated, and the user.
 
 @see https://radar.io/documentation/sdk#ios-foreground
 */
typedef void(^ _Nullable RadarTrackCompletionHandler)(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user);

/**
 Called when a place search request succeeds, fails, or times out. Receives the request status and, if successful, the location and an array of places sorted by distance.
 
 @see https://radar.io/documentation/sdk#ios-search
 */
typedef void(^ _Nonnull RadarSearchPlacesCompletionHandler)(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarPlace *> * _Nullable places);

/**
 Called when a geofence search request succeeds, fails, or times out. Receives the request status and, if successful, the location and an array of geofences sorted by distance.

 @see https://radar.io/documentation/sdk#ios-search
 */
typedef void(^ _Nonnull RadarSearchGeofencesCompletionHandler)(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarGeofence *> * _Nullable geofences);

/**
 Called when a forward or reverse geocoding request succeeds, fails, or times out. Receives the request status and, if successful, the raw response and an array of addresses.

 @see https://radar.io/documentation/geocoding
 */
typedef void(^ _Nonnull RadarGeocodeCompletionHandler)(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses);

/**
 Called when an IP geocoding request succeeds, fails, or times out. Receives the request status and, if successful, the raw response and region of the IP.

 @see https://radar.io/documentation/geocoding
 */
typedef void(^ _Nonnull RadarIPGeocodeCompletionHandler)(RadarStatus status, RadarRegion * _Nullable country);

/**
 The main class used to interact with the Radar SDK.
 
 @see https://radar.io/documentation/sdk
 */
@interface Radar : NSObject

/**
 Initializes the Radar SDK.
 
 @warning Call this method from the main thread in your `AppDelegate` class before calling any other Radar methods.
 
 @param publishableKey Your publishable API key.
 
 @see https://radar.io/documentation/sdk#ios-initialize
 */
+ (void)initializeWithPublishableKey:(NSString * _Nonnull)publishableKey
    NS_SWIFT_NAME(initialize(publishableKey:));

/**
 Identifies the user.
 
 @note Until you identify the user, Radar will automatically identify the user by `deviceId` (IDFV).
 
 @param userId A stable unique ID for the user. If `nil`, the previous `userId` will be cleared.
 
 @see https://radar.io/documentation/sdk#ios-identify
 */
+ (void)setUserId:(NSString * _Nullable)userId;

/**
 Returns the current `userId`.
 
 @return The current `userId`.
 */
+ (NSString * _Nullable)getUserId;

/**
 Sets an optional description for the user, displayed in the dashboard.
 
 @param description A description for the user. If `nil`, the previous `description` will be cleared.
 
 @see https://radar.io/documentation/sdk#ios-identify
 */
+ (void)setDescription:(NSString * _Nullable)description;

/**
 Returns the current `description`.
 
 @return The current `description`.
 */
+ (NSString * _Nullable)getDescription;

/**
 Sets an optional set of custom key-value pairs for the user.
 
 @param metadata A set of custom key-value pairs for the user. Must have 16 or fewer keys and values of type string, boolean, or number. If `nil`, the previous `metadata` will be cleared.
 */
+ (void)setMetadata:(NSDictionary * _Nullable)metadata;

/**
 Returns the current `metadata`.
 
 @return The current `metadata`.
 */
+ (NSDictionary * _Nullable)getMetadata;

/**
 Gets the device's current location.
 
 @param completionHandler An optional completion handler.
 */
+ (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler
    NS_SWIFT_NAME(getLocation(completionHandler:));

/**
 Tracks the user's location once in the foreground.
 
 @warning Note that these calls are subject to rate limits.
 
 @param completionHandler An optional completion handler.
 
 @see https://radar.io/documentation/sdk#ios-foreground
 */
+ (void)trackOnceWithCompletionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler
    NS_SWIFT_NAME(trackOnce(completionHandler:));

/**
 Manually updates the user's location.

 @warning Note that these calls are subject to rate limits.
 
 @param location A location for the user.
 @param completionHandler An optional completion handler.
 
 @see https://radar.io/documentation/sdk#ios-manual
 */
+ (void)trackOnceWithLocation:(CLLocation * _Nonnull)location
            completionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler
    NS_SWIFT_NAME(trackOnce(location:completionHandler:));

/**
 Starts tracking the user's location in the background.
 
 @warning Before calling this method, the user's location authorization status must be `kCLAuthorizationStatusAuthorizedAlways`.
 
 @see https://radar.io/documentation/sdk#ios-background
 */
+ (void)startTracking;

/**
 Starts tracking the user's location in the background with configurable tracking options.
 
 @warning Before calling this method, the user's location authorization status should be `kCLAuthorizationStatusAuthorizedAlways`.
 
 @param options Configurable tracking options.
 
 @see https://radar.io/documentation/sdk#ios-background
**/
+ (void)startTrackingWithOptions:(RadarTrackingOptions *)options
    NS_SWIFT_NAME(startTracking(trackingOptions:));

/**
 Stops tracking the user's location in the background.
 
 @see https://radar.io/documentation/sdk#ios-background
 */
+ (void)stopTracking;

/**
 Returns a boolean indicating whether tracking has been started.
 
 @return A boolean indicating whether tracking has been started.
 */
+ (BOOL)isTracking;

/**
 Returns the current tracking options.
 
 @return The current tracking options.
 */
+ (RadarTrackingOptions *)getTrackingOptions;

/**
 Sets a delegate for client-side delivery of events, location updates, and debug logs.
 
 @param delegate A delegate for client-side delivery of events, location updates, and debug logs. If `nil`, the previous delegate will be cleared.
 
 @see https://radar.io/documentation/sdk#ios-background
 */
+ (void)setDelegate:(nullable id <RadarDelegate>)delegate;

/**
 Accepts an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.
 
 @param eventId The ID of the event to accept.
 @param verifiedPlaceId For place entry events, the ID of the verified place. May be `nil`.
 
 @see https://radar.io/documentation/sdk#ios-verify
 */
+ (void)acceptEventId:(NSString *_Nonnull)eventId
      verifiedPlaceId:(NSString *_Nullable)verifiedPlaceId
    NS_SWIFT_NAME(acceptEventId(_:verifiedPlaceId:));

/**
 Rejects an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and confidence level of future events.
 
 @param eventId The ID of the event to reject.
 
 @see https://radar.io/documentation/sdk#ios-verify
 */
+ (void)rejectEventId:(NSString *_Nonnull)eventId
    NS_SWIFT_NAME(rejectEventId(_:));

/**
 Gets the device's current location, then searches for places near that location, sorted by distance.
 
 @warning You may specify only one of chains, categories, or groups.

 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param chains An array of chain slugs to filter. See https://radar.io/documentation/places/chains
 @param categories An array of categories to filter. See: https://radar.io/documentation/places/categories
 @param groups An array of groups to filter. See https://radar.io/documentation/places/groups
 @param limit The max number of places to return. A number between 1 and 100.
 @param completionHandler A completion handler.
*/
+ (void)searchPlacesWithRadius:(int)radius
                        chains:(NSArray * _Nullable)chains
                    categories:(NSArray * _Nullable)categories
                        groups:(NSArray * _Nullable)groups
                         limit:(int)limit
             completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler
    NS_SWIFT_NAME(searchPlaces(radius:chains:categories:groups:limit:completionHandler:));

/**
 Searches for places near a location, sorted by distance.
 
 @warning You may specify only one of chains, categories, or groups.

 @param location The location to search.
 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param chains An array of chain slugs to filter. See https://radar.io/documentation/places/chains
 @param categories An array of categories to filter. See: https://radar.io/documentation/places/categories
 @param groups An array of groups to filter. See https://radar.io/documentation/places/groups
 @param limit The max number of places to return. A number between 1 and 100.
 @param completionHandler A completion handler.
*/
+ (void)searchPlacesWithLocation:(CLLocation *)location
                          radius:(int)radius
                          chains:(NSArray * _Nullable)chains
                      categories:(NSArray * _Nullable)categories
                          groups:(NSArray * _Nullable)groups
                           limit:(int)limit
               completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler
    NS_SWIFT_NAME(searchPlaces(location:radius:chains:categories:groups:limit:completionHandler:));


/**
 Gets the device's current location, then searches for geofences near that location, sorted by distance.

 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param tags An array of tags to filter. See https://radar.io/documentation/geofences
 @param limit The max number of geofences to return. A number between 1 and 100.
 @param completionHandler A completion handler.
*/
+ (void)searchGeofencesWithRadius:(int)radius
                             tags:(NSArray * _Nullable)tags
                            limit:(int)limit
                completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler
    NS_SWIFT_NAME(searchGeofences(radius:tags:limit:completionHandler:));

/**
 Searches for geofences near a location, sorted by distance.

 @param location The location to search.
 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param tags An array of tags to filter. See https://radar.io/documentation/geofences
 @param limit The max number of geofences to return. A number between 1 and 100.
 @param completionHandler A completion handler.
*/
+ (void)searchGeofencesWithLocation:(CLLocation *)location
                             radius:(int)radius
                               tags:(NSArray * _Nullable)tags
                              limit:(int)limit
                  completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler
    NS_SWIFT_NAME(searchGeofences(location:radius:tags:limit:completionHandler:));

/**
 Geocodes an address, converting address to coordinates.

 @param query The address to geocode.
 @param completionHandler A completion handler.
 */
+ (void)geocode:(NSString * _Nonnull)query
        completionHandler:(RadarGeocodeCompletionHandler)completionHandler;

/**
 Gets the device's current location, then reverse geocodes that location, converting coordinates to address.
 
 @param completionHandler A completion handler.
 */
+(void)reverseGeocode:(RadarGeocodeCompletionHandler)completionHandler;

/**
 Reverse geocodes a location, converting coordinates to address.

 @param location The location to reverse geocode.
 @param completionHandler A completion handler.
 */
+ (void)reverseGeocodeLocation:(CLLocation * _Nonnull)location
             completionHandler:(RadarGeocodeCompletionHandler)completionHandler;

/**
 Geocodes the device's current IP address, converting IP address to country.

 @param completionHandler A completion handler.
 */
+ (void)geocodeDeviceIP:(RadarIPGeocodeCompletionHandler)completionHandler;

/**
 Geocodes an IP address, converting IP address to country.

 @param IP The IP address to geocode.
 @param completionHandler A completion handler.
 */
+ (void)geocodeIP:(NSString * _Nonnull)IP
completionHandler:(RadarIPGeocodeCompletionHandler)completionHandler;

/**
 Sets the log level for debug logs.
 
 @param level The log level.
 */
+ (void)setLogLevel:(RadarLogLevel)level;

/**
 Returns a display string for a status value.
 
 @param status A status value.
 
 @return A display string for the status value.
 */
+ (NSString *)stringForStatus:(RadarStatus)status
    NS_SWIFT_NAME(stringForStatus(_:));

/**
 Returns a display string for a location source value.
 
 @param source A location source value.
 
 @return A display string for the location source value.
 */
+ (NSString *)stringForSource:(RadarLocationSource)source
    NS_SWIFT_NAME(stringForSource(_:));;

@end

NS_ASSUME_NONNULL_END
