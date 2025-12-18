//
//  RadarTripLeg.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a leg of a multi-destination trip.

 @see https://radar.com/documentation/trip-tracking
 */
@interface RadarTripLeg : NSObject

#pragma mark - Geofence Destination Properties

/**
 The tag of the destination geofence for this leg.
 Use with destinationGeofenceExternalId for geofence-based destinations.
 */
@property (nullable, nonatomic, copy) NSString *destinationGeofenceTag;

/**
 The external ID of the destination geofence for this leg.
 Use with destinationGeofenceTag for geofence-based destinations.
 */
@property (nullable, nonatomic, copy) NSString *destinationGeofenceExternalId;

/**
 The Radar ID of the destination geofence for this leg.
 Alternative to using destinationGeofenceTag + destinationGeofenceExternalId.
 */
@property (nullable, nonatomic, copy) NSString *destinationGeofenceId;

#pragma mark - Address Destination Properties

/**
 The address string for the destination of this leg.
 Use for address-based destinations.
 */
@property (nullable, nonatomic, copy) NSString *address;

#pragma mark - Coordinate Destination Properties

/**
 The coordinates for the destination of this leg.
 Use for coordinate-based destinations. Set latitude and longitude.
 */
@property (nonatomic, assign) CLLocationCoordinate2D coordinates;

/**
 Whether coordinates have been explicitly set.
 */
@property (nonatomic, assign, readonly) BOOL hasCoordinates;

/**
 The arrival radius in meters for coordinate-based destinations.
 Only used when coordinates are set.
 */
@property (nonatomic, assign) NSInteger arrivalRadius;

#pragma mark - Common Properties

/**
 The stop duration in minutes for this leg.
 */
@property (nonatomic, assign) NSInteger stopDuration;

/**
 An optional set of custom key-value pairs for this leg.
 */
@property (nullable, nonatomic, copy) NSDictionary *metadata;

#pragma mark - Initializers

/**
 Initializes a RadarTripLeg with the specified destination geofence tag and external ID.
 
 @param destinationGeofenceTag The tag of the destination geofence.
 @param destinationGeofenceExternalId The external ID of the destination geofence.
 
 @return A new RadarTripLeg instance.
 */
- (instancetype)initWithDestinationGeofenceTag:(NSString *_Nullable)destinationGeofenceTag
                 destinationGeofenceExternalId:(NSString *_Nullable)destinationGeofenceExternalId;

/**
 Initializes a RadarTripLeg with the specified destination geofence ID.
 
 @param destinationGeofenceId The Radar ID of the destination geofence.
 
 @return A new RadarTripLeg instance.
 */
- (instancetype)initWithDestinationGeofenceId:(NSString *_Nonnull)destinationGeofenceId;

/**
 Initializes a RadarTripLeg with the specified address.
 
 @param address The address string for the destination.
 
 @return A new RadarTripLeg instance.
 */
- (instancetype)initWithAddress:(NSString *_Nonnull)address;

/**
 Initializes a RadarTripLeg with the specified coordinates.
 
 @param coordinates The coordinates for the destination.
 
 @return A new RadarTripLeg instance.
 */
- (instancetype)initWithCoordinates:(CLLocationCoordinate2D)coordinates;

/**
 Initializes a RadarTripLeg with the specified coordinates and arrival radius.
 
 @param coordinates The coordinates for the destination.
 @param arrivalRadius The arrival radius in meters.
 
 @return A new RadarTripLeg instance.
 */
- (instancetype)initWithCoordinates:(CLLocationCoordinate2D)coordinates
                      arrivalRadius:(NSInteger)arrivalRadius;

/**
 Sets the coordinates for this leg's destination.
 
 @param coordinates The coordinates for the destination.
 */
- (void)setDestinationCoordinates:(CLLocationCoordinate2D)coordinates;

/**
 Creates a RadarTripLeg from a dictionary representation.
 
 @param dict The dictionary containing leg data.
 
 @return A new RadarTripLeg instance, or nil if the dictionary is invalid.
 */
+ (RadarTripLeg *_Nullable)legFromDictionary:(NSDictionary *_Nullable)dict;

/**
 Creates an array of RadarTripLeg objects from an array of dictionaries.
 
 @param array The array of dictionaries containing leg data.
 
 @return An array of RadarTripLeg instances, or nil if the array is invalid.
 */
+ (NSArray<RadarTripLeg *> *_Nullable)legsFromArray:(NSArray *_Nullable)array;

/**
 Converts the leg to a dictionary representation for API serialization.
 
 @return A dictionary representation of the leg.
 */
- (NSDictionary *)dictionaryValue;

/**
 Converts an array of legs to an array of dictionaries.
 
 @param legs The array of RadarTripLeg instances.
 
 @return An array of dictionary representations.
 */
+ (NSArray<NSDictionary *> *_Nullable)arrayForLegs:(NSArray<RadarTripLeg *> *_Nullable)legs;

@end

NS_ASSUME_NONNULL_END

