//
//  Radar.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RadarAddress.h"
#import "RadarContext.h"
#import "RadarEvent.h"
#import "RadarRegion.h"
#import "RadarRouteMatrix.h"
#import "RadarRoutes.h"
#import "RadarTrackingOptions.h"
#import "RadarUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarDelegate;
@class RadarTripOptions;

/**
 The status types for a request.

 @see https://radar.io/documentation/sdk/ios#foreground-tracking
 */
typedef NS_ENUM(NSInteger, RadarStatus) {
    /// Success
    RadarStatusSuccess,
    /// SDK not initialized
    RadarStatusErrorPublishableKey,
    /// Location permissions not granted
    RadarStatusErrorPermissions,
    /// Location services error or timeout (20 seconds)
    RadarStatusErrorLocation,
    /// Beacon ranging error or timeout (5 seconds)
    RadarStatusErrorBluetooth,
    /// Network error or timeout (10 seconds)
    RadarStatusErrorNetwork,
    /// Bad request (missing or invalid params)
    RadarStatusErrorBadRequest,
    /// Unauthorized (invalid API key)
    RadarStatusErrorUnauthorized,
    /// Payment required (organization disabled or usage exceeded)
    RadarStatusErrorPaymentRequired,
    /// Forbidden (insufficient permissions or no beta access)
    RadarStatusErrorForbidden,
    /// Not found
    RadarStatusErrorNotFound,
    /// Too many requests (rate limit exceeded)
    RadarStatusErrorRateLimit,
    /// Internal server error
    RadarStatusErrorServer,
    /// Unknown error
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
    /// Mock
    RadarLocationSourceMockLocation,
    /// Beacon enter
    RadarLocationSourceBeaconEnter,
    /// Beacon exit
    RadarLocationSourceBeaconExit,
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
 The travel modes for routes.

 @see https://radar.io/documentation/api#routing
 */
typedef NS_OPTIONS(NSInteger, RadarRouteMode) {
    /// Foot
    RadarRouteModeFoot NS_SWIFT_NAME(foot) = 1 << 0,
    /// Bike
    RadarRouteModeBike NS_SWIFT_NAME(bike) = 1 << 1,
    /// Car
    RadarRouteModeCar NS_SWIFT_NAME(car) = 1 << 2,
    /// Truck
    RadarRouteModeTruck NS_SWIFT_NAME(truck) = 1 << 3,
    /// Motorbike
    RadarRouteModeMotorbike NS_SWIFT_NAME(motorbike) = 1 << 4
};

/**
 The distance units for routes.

 @see https://radar.io/documentation/api#routing
 */
typedef NS_ENUM(NSInteger, RadarRouteUnits) {
    /// Imperial (feet)
    RadarRouteUnitsImperial NS_SWIFT_NAME(imperial),
    /// Metric (meters)
    RadarRouteUnitsMetric NS_SWIFT_NAME(metric)
};

/**
 Called when a location request succeeds, fails, or times out.

 Receives the request status and, if successful, the location.

 @see https://radar.io/documentation/sdk/ios#get-location
 */
typedef void (^_Nullable RadarLocationCompletionHandler)(RadarStatus status, CLLocation *_Nullable location, BOOL stopped);

/**
 Called when a beacon ranging request succeeds, fails, or times out.

 Receives the request status and, if successful, the nearby beacon identifiers.

 @see https://radar.io/documentation/beacons
 */
typedef void (^_Nullable RadarBeaconCompletionHandler)(RadarStatus status, NSArray<NSString *> *_Nullable nearbyBeacons);

/**
 Called when a track request succeeds, fails, or times out.

 Receives the request status and, if successful, the user's location, an array of the events generated, and the user.

 @see https://radar.io/documentation/sdk/ios
 */
typedef void (^_Nullable RadarTrackCompletionHandler)(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user);

/**
 Called when a trip update succeeds, fails, or times out.

 Receives the request status.

 @see https://radar.io/documentation/sdk/ios
 */
typedef void (^_Nullable RadarTripCompletionHandler)(RadarStatus status);

/**
 Called when a context request succeeds, fails, or times out.

 Receives the request status and, if successful, the location and the context.

 @see https://radar.io/documentation/api#context
 */
typedef void (^_Nonnull RadarContextCompletionHandler)(RadarStatus status, CLLocation *_Nullable location, RadarContext *_Nullable context);

/**
 Called when a place search request succeeds, fails, or times out.

 Receives the request status and, if successful, the location and an array of places sorted by distance.

 @see https://radar.io/documentation/api#search-places
 */
typedef void (^_Nonnull RadarSearchPlacesCompletionHandler)(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarPlace *> *_Nullable places);

/**
 Called when a geofence search request succeeds, fails, or times out.

 Receives the request status and, if successful, the location and an array of geofences sorted by distance.

 @see https://radar.io/documentation/api#search-geofences
 */
typedef void (^_Nonnull RadarSearchGeofencesCompletionHandler)(RadarStatus status, CLLocation *_Nullable location, NSArray<RadarGeofence *> *_Nullable geofences);

/**
 Called when a geocoding request succeeds, fails, or times out.

 Receives the request status and, if successful, the geocoding results (an array of addresses).

 @see https://radar.io/documentation/api#forward-geocode
 */
typedef void (^_Nonnull RadarGeocodeCompletionHandler)(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses);

/**
 Called when an IP geocoding request succeeds, fails, or times out.

 Receives the request status and, if successful, the geocoding result (a partial address) and a boolean indicating whether the IP address is a known proxy.

 @see https://radar.io/documentation/api#ip-geocode
 */
typedef void (^_Nonnull RadarIPGeocodeCompletionHandler)(RadarStatus status, RadarAddress *_Nullable address, BOOL proxy);

/**
 Called when a distance request succeeds, fails, or times out.

 Receives the request status and, if successful, the routes.

 @see https://radar.io/documentation/api#distance
 */
typedef void (^_Nonnull RadarRouteCompletionHandler)(RadarStatus status, RadarRoutes *_Nullable routes);

/**
 Called when a matrix request succeeds, fails, or times out.

 Receives the request status and, if successful, the matrix.

 @see https://radar.io/documentation/api#matrix
 */
typedef void (^_Nonnull RadarRouteMatrixCompletionHandler)(RadarStatus status, RadarRouteMatrix *_Nullable matrix);

/**
 The main class used to interact with the Radar SDK.

 @see https://radar.io/documentation/sdk
 */
@interface Radar : NSObject

/**
 Initializes the Radar SDK.

 @warning Call this method from the main thread in your `AppDelegate` class before calling any other Radar methods.

 @param publishableKey Your publishable API key.

 @see https://radar.io/documentation/sdk/ios#initialize-sdk
 */
+ (void)initializeWithPublishableKey:(NSString *_Nonnull)publishableKey NS_SWIFT_NAME(initialize(publishableKey:));

/**
 Identifies the user.

 @note Until you identify the user, Radar will automatically identify the user by `deviceId` (IDFV).

 @param userId A stable unique ID for the user. If `nil`, the previous `userId` will be cleared.

 @see https://radar.io/documentation/sdk/ios#identify-user
 */
+ (void)setUserId:(NSString *_Nullable)userId;

/**
 Returns the current `userId`.

 @return The current `userId`.

 @see https://radar.io/documentation/sdk/ios#identify-user
 */
+ (NSString *_Nullable)getUserId;

/**
 Sets an optional description for the user, displayed in the dashboard.

 @param description A description for the user. If `nil`, the previous `description` will be cleared.

 @see https://radar.io/documentation/sdk/ios#identify-user
 */
+ (void)setDescription:(NSString *_Nullable)description;

/**
 Returns the current `description`.

 @return The current `description`.

 @see https://radar.io/documentation/sdk/ios#identify-user
 */
+ (NSString *_Nullable)getDescription;

/**
 Sets an optional set of custom key-value pairs for the user.

 @param metadata A set of custom key-value pairs for the user. Must have 16 or fewer keys and values of type string, boolean, or number. If `nil`, the previous
 `metadata` will be cleared.

 @see https://radar.io/documentation/sdk/ios#identify-user
 */
+ (void)setMetadata:(NSDictionary *_Nullable)metadata;

/**
 Returns the current `metadata`.

 @return The current `metadata`.

 @see https://radar.io/documentation/sdk/ios#identify-user
 */
+ (NSDictionary *_Nullable)getMetadata;

/**
 Enables `adId` (IDFA) collection. Disabled by default.

 @param enabled A boolean indicating whether `adId` should be collected.
 */
+ (void)setAdIdEnabled:(BOOL)enabled;

/**
 Gets the device's current location.

 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/sdk/ios#get-location
 */
+ (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(getLocation(completionHandler:));

/**
 Gets the device's current location with the desired accuracy.

 @param desiredAccuracy The desired accuracy.
 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/sdk/ios#get-location
 */
+ (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                     completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(getLocation(desiredAccuracy:completionHandler:));

/**
 Tracks the user's location once in the foreground.

 @warning Note that these calls are subject to rate limits.

 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/sdk/ios#foreground-tracking
 */
+ (void)trackOnceWithCompletionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(trackOnce(completionHandler:));

/**
 Tracks the user's location once with the desired accuracy and optionally ranges beacons in the foreground.

 @warning Note that these calls are subject to rate limits.

 @param desiredAccuracy The desired accuracy.
 @param beacons A boolean indicating whether to range beacons.
 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/sdk/ios#foreground-tracking
 */
+ (void)trackOnceWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                             beacons:(BOOL)beacons
                   completionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(trackOnce(desiredAccuracy:beacons:completionHandler:));

/**
 Manually updates the user's location.

 @warning Note that these calls are subject to rate limits.

 @param location A location for the user.
 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/sdk/ios#foreground-tracking
 */
+ (void)trackOnceWithLocation:(CLLocation *_Nonnull)location
            completionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(trackOnce(location:completionHandler:));

/**
 Starts tracking the user's location in the background with configurable tracking options.

 @param options Configurable tracking options.

 @see https://radar.io/documentation/sdk/ios#background-tracking-for-geofencing
 */
+ (void)startTrackingWithOptions:(RadarTrackingOptions *)options NS_SWIFT_NAME(startTracking(trackingOptions:));

/**
 Mocks tracking the user's location from an origin to a destination.

 @param origin The origin.
 @param destination The destination.
 @param mode The travel mode.
 @param steps The number of mock location updates.
 @param interval The interval in seconds between each mock location update. A number between 1 and 60.

 @see https://radar.io/documentation/sdk/ios#mock-tracking-for-testing
 */
+ (void)mockTrackingWithOrigin:(CLLocation *_Nonnull)origin
                   destination:(CLLocation *_Nonnull)destination
                          mode:(RadarRouteMode)mode
                         steps:(int)steps
                      interval:(NSTimeInterval)interval
             completionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(mockTracking(origin:destination:mode:steps:interval:completionHandler:));

/**
 Stops tracking the user's location in the background.

 @see https://radar.io/documentation/sdk/ios#background-tracking-for-geofencing
 */
+ (void)stopTracking;

/**
 Returns a boolean indicating whether tracking has been started.

 @return A boolean indicating whether tracking has been started.

 @see https://radar.io/documentation/sdk/ios#background-tracking-for-geofencing
 */
+ (BOOL)isTracking;

/**
 Returns the current tracking options.

 @return The current tracking options.

 @see https://radar.io/documentation/sdk/tracking
 */
+ (RadarTrackingOptions *)getTrackingOptions;

/**
 Sets a delegate for client-side delivery of events, location updates, and debug logs.

 @param delegate A delegate for client-side delivery of events, location updates, and debug logs. If `nil`, the previous delegate will be cleared.

 @see https://radar.io/documentation/sdk/ios#listening-for-events-with-a-delegate
 */
+ (void)setDelegate:(nullable id<RadarDelegate>)delegate;

/**
 Accepts an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and
 confidence level of future events.

 @param eventId The ID of the event to accept.
 @param verifiedPlaceId For place entry events, the ID of the verified place. May be `nil`.

 @see https://radar.io/documentation/places#verify-events
 */
+ (void)acceptEventId:(NSString *_Nonnull)eventId verifiedPlaceId:(NSString *_Nullable)verifiedPlaceId NS_SWIFT_NAME(acceptEventId(_:verifiedPlaceId:));

/**
 Rejects an event. Events can be accepted after user check-ins or other forms of verification. Event verifications will be used to improve the accuracy and
 confidence level of future events.

 @param eventId The ID of the event to reject.

 @see https://radar.io/documentation/places#verify-events
 */
+ (void)rejectEventId:(NSString *_Nonnull)eventId NS_SWIFT_NAME(rejectEventId(_:));

/**
 Returns the current trip options.

 @return The current trip options.

 @see https://radar.io/documentation/trip-tracking
 */
+ (RadarTripOptions *_Nullable)getTripOptions;

/**
 Starts a trip.

 @param options Configurable trip options.

 @see https://radar.io/documentation/trip-tracking
 */
+ (void)startTripWithOptions:(RadarTripOptions *_Nonnull)options NS_SWIFT_NAME(startTrip(options:));

/**
 Starts a trip.

 @param options Configurable trip options.
 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/trip-tracking
 */
+ (void)startTripWithOptions:(RadarTripOptions *_Nonnull)options
           completionHandler:(RadarTripCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(startTrip(options:completionHandler:));

/**
 Manually updates a trip.

 @param options Configurable trip options.
 @param status The trip status. To avoid updating status, pass RadarTripStatusUnknown.
 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/trip-tracking
 */
+ (void)updateTripWithOptions:(RadarTripOptions *_Nonnull)options
                       status:(RadarTripStatus)status
            completionHandler:(RadarTripCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(updateTrip(options:status:completionHandler:));

/**
 Completes a trip.

 @see https://radar.io/documentation/trip-tracking
 */
+ (void)completeTrip;

/**
 Completes a trip.

 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/trip-tracking
 */
+ (void)completeTripWithCompletionHandler:(RadarTripCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(completeTrip(completionHandler:));

/**
 Cancels a trip.

 @see https://radar.io/documentation/trip-tracking
 */
+ (void)cancelTrip;

/**
 Cancels a trip.

 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/trip-tracking
 */
+ (void)cancelTripWithCompletionHandler:(RadarTripCompletionHandler _Nullable)completionHandler NS_SWIFT_NAME(cancelTrip(completionHandler:));

/**
 Gets the device's current location, then gets context for that location without sending device or user identifiers to the server.

 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/api#search-geofences
 */
+ (void)getContextWithCompletionHandler:(RadarContextCompletionHandler _Nonnull)completionHandler NS_SWIFT_NAME(getContext(completionHandler:));

/**
 Gets context for a location without sending device or user identifiers to the server.

 @param location The location.
 @param completionHandler An optional completion handler.

 @see https://radar.io/documentation/api#context
 */
+ (void)getContextForLocation:(CLLocation *_Nonnull)location
            completionHandler:(RadarContextCompletionHandler _Nonnull)completionHandler NS_SWIFT_NAME(getContext(location:completionHandler:));

/**
 Gets the device's current location, then searches for places near that location, sorted by distance.

 @warning You may specify only one of chains, categories, or groups.

 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param chains An array of chain slugs to filter. See https://radar.io/documentation/places/chains
 @param categories An array of categories to filter. See: https://radar.io/documentation/places/categories
 @param groups An array of groups to filter. See https://radar.io/documentation/places/groups
 @param limit The max number of places to return. A number between 1 and 100.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#search-places
 */
+ (void)searchPlacesWithRadius:(int)radius
                        chains:(NSArray<NSString *> *_Nullable)chains
                    categories:(NSArray<NSString *> *_Nullable)categories
                        groups:(NSArray<NSString *> *_Nullable)groups
                         limit:(int)limit
             completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler NS_SWIFT_NAME(searchPlaces(radius:chains:categories:groups:limit:completionHandler:));

/**
 Searches for places near a location, sorted by distance.

 @warning You may specify only one of chains, categories, or groups.

 @param near The location to search.
 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param chains An array of chain slugs to filter. See https://radar.io/documentation/places/chains
 @param categories An array of categories to filter. See: https://radar.io/documentation/places/categories
 @param groups An array of groups to filter. See https://radar.io/documentation/places/groups
 @param limit The max number of places to return. A number between 1 and 100.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#search-places
 */
+ (void)searchPlacesNear:(CLLocation *)near
                  radius:(int)radius
                  chains:(NSArray<NSString *> *_Nullable)chains
              categories:(NSArray<NSString *> *_Nullable)categories
                  groups:(NSArray<NSString *> *_Nullable)groups
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler NS_SWIFT_NAME(searchPlaces(near:radius:chains:categories:groups:limit:completionHandler:));

/**
 Gets the device's current location, then searches for geofences near that location, sorted by distance.

 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param tags An array of tags to filter. See https://radar.io/documentation/geofences
 @param metadata A dictionary of metadata to filter. See https://radar.io/documentation/geofences
 @param limit The max number of geofences to return. A number between 1 and 100.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#search-geofences
 */
+ (void)searchGeofencesWithRadius:(int)radius
                             tags:(NSArray<NSString *> *_Nullable)tags
                         metadata:(NSDictionary *_Nullable)metadata
                            limit:(int)limit
                completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler NS_SWIFT_NAME(searchGeofences(radius:tags:metadata:limit:completionHandler:));

/**
 Searches for geofences near a location, sorted by distance.

 @param near The location to search.
 @param radius The radius to search, in meters. A number between 100 and 10000.
 @param tags An array of tags to filter. See https://radar.io/documentation/geofences
 @param metadata A dictionary of metadata to filter. See https://radar.io/documentation/geofences
 @param limit The max number of geofences to return. A number between 1 and 100.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#search-geofences
 */
+ (void)searchGeofencesNear:(CLLocation *)near
                     radius:(int)radius
                       tags:(NSArray<NSString *> *_Nullable)tags
                   metadata:(NSDictionary *_Nullable)metadata
                      limit:(int)limit
          completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler NS_SWIFT_NAME(searchGeofences(near:radius:tags:metadata:limit:completionHandler:));

/**
 Autocompletes partial addresses and place names, sorted by relevance.

 @param query The partial address or place name to autocomplete.
 @param near A location for the search.
 @param limit The max number of addresses to return. A number between 1 and 100.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#autocomplete
 */
+ (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nonnull)near
                    limit:(int)limit
        completionHandler:(RadarGeocodeCompletionHandler)completionHandler NS_SWIFT_NAME(autocomplete(query:near:limit:completionHandler:));

/**
 Geocodes an address, converting address to coordinates.

 @param query The address to geocode.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#forward-geocode
 */
+ (void)geocodeAddress:(NSString *_Nonnull)query completionHandler:(RadarGeocodeCompletionHandler)completionHandler NS_SWIFT_NAME(geocode(address:completionHandler:));

/**
 Gets the device's current location, then reverse geocodes that location, converting coordinates to address.

 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#reverse-geocode
 */
+ (void)reverseGeocodeWithCompletionHandler:(RadarGeocodeCompletionHandler)completionHandler NS_SWIFT_NAME(reverseGeocode(completionHandler:));

/**
 Reverse geocodes a location, converting coordinates to address.

 @param location The location to reverse geocode.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#reverse-geocode
 */
+ (void)reverseGeocodeLocation:(CLLocation *_Nonnull)location
             completionHandler:(RadarGeocodeCompletionHandler)completionHandler NS_SWIFT_NAME(reverseGeocode(location:completionHandler:));

/**
 Geocodes the device's current IP address, converting IP address to partial address.

 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#ip-geocode
 */
+ (void)ipGeocodeWithCompletionHandler:(RadarIPGeocodeCompletionHandler)completionHandler NS_SWIFT_NAME(ipGeocode(completionHandler:));

/**
 Gets the device's current location, then calculates the travel distance and duration to a destination.

 @param destination The destination.
 @param modes The travel modes.
 @param units The distance units.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#distance
 */
+ (void)getDistanceToDestination:(CLLocation *_Nonnull)destination
                           modes:(RadarRouteMode)modes
                           units:(RadarRouteUnits)units
               completionHandler:(RadarRouteCompletionHandler)completionHandler NS_SWIFT_NAME(getDistance(destination:modes:units:completionHandler:));

/**
 Calculates the travel distance and duration from an origin to a destination.

 @param origin The origin.
 @param destination The destination.
 @param modes The travel modes.
 @param units The distance units.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#distance
 */
+ (void)getDistanceFromOrigin:(CLLocation *_Nonnull)origin
                  destination:(CLLocation *_Nonnull)destination
                        modes:(RadarRouteMode)modes
                        units:(RadarRouteUnits)units
            completionHandler:(RadarRouteCompletionHandler)completionHandler NS_SWIFT_NAME(getDistance(origin:destination:modes:units:completionHandler:));

/**
 Calculates the travel distances and durations between multiple origins and destinations for up to 25 routes.

 @param origins The origins.
 @param destinations The destinations.
 @param mode The travel mode.
 @param units The distance units.
 @param completionHandler A completion handler.

 @see https://radar.io/documentation/api#matrix
 */
+ (void)getMatrixFromOrigins:(NSArray<CLLocation *> *_Nonnull)origins
                destinations:(NSArray<CLLocation *> *_Nonnull)destinations
                        mode:(RadarRouteMode)mode
                       units:(RadarRouteUnits)units
           completionHandler:(RadarRouteMatrixCompletionHandler)completionHandler NS_SWIFT_NAME(getMatrix(origins:destinations:mode:units:completionHandler:));

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
+ (NSString *)stringForStatus:(RadarStatus)status NS_SWIFT_NAME(stringForStatus(_:));

/**
 Returns a display string for a location source value.

 @param source A location source value.

 @return A display string for the location source value.
 */
+ (NSString *)stringForSource:(RadarLocationSource)source NS_SWIFT_NAME(stringForSource(_:));

/**
 Returns a display string for a travel mode value.

 @param mode A travel mode value.

 @return A display string for the travel mode value.
 */
+ (NSString *)stringForMode:(RadarRouteMode)mode NS_SWIFT_NAME(stringForMode(_:));

/**
 Returns a display string for a trip status value.

 @param status A trip status value.

 @return A display string for the trip status value.
 */
+ (NSString *)stringForTripStatus:(RadarTripStatus)status NS_SWIFT_NAME(stringForTripStatus(_:));

/**
 Returns a dictionary for a location.

 @param location A location.

 @return A dictionary for the location.
 */
+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location NS_SWIFT_NAME(dictionaryForLocation(_:));

@end

NS_ASSUME_NONNULL_END
