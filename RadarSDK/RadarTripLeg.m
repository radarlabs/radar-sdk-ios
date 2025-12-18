//
//  RadarTripLeg.m
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "Include/RadarTripLeg.h"

@implementation RadarTripLeg {
    BOOL _hasCoordinates;
}

static NSString *const kDestination = @"destination";
static NSString *const kDestinationGeofenceTag = @"destinationGeofenceTag";
static NSString *const kDestinationGeofenceExternalId = @"destinationGeofenceExternalId";
static NSString *const kDestinationGeofenceId = @"destinationGeofenceId";
static NSString *const kAddress = @"address";
static NSString *const kCoordinates = @"coordinates";
static NSString *const kArrivalRadius = @"arrivalRadius";
static NSString *const kStopDuration = @"stopDuration";
static NSString *const kMetadata = @"metadata";

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        _stopDuration = 0;
        _arrivalRadius = 0;
        _hasCoordinates = NO;
        _coordinates = kCLLocationCoordinate2DInvalid;
    }
    return self;
}

- (instancetype)initWithDestinationGeofenceTag:(NSString *_Nullable)destinationGeofenceTag
                 destinationGeofenceExternalId:(NSString *_Nullable)destinationGeofenceExternalId {
    self = [self init];
    if (self) {
        _destinationGeofenceTag = destinationGeofenceTag;
        _destinationGeofenceExternalId = destinationGeofenceExternalId;
    }
    return self;
}

- (instancetype)initWithDestinationGeofenceId:(NSString *_Nonnull)destinationGeofenceId {
    self = [self init];
    if (self) {
        _destinationGeofenceId = destinationGeofenceId;
    }
    return self;
}

- (instancetype)initWithAddress:(NSString *_Nonnull)address {
    self = [self init];
    if (self) {
        _address = address;
    }
    return self;
}

- (instancetype)initWithCoordinates:(CLLocationCoordinate2D)coordinates {
    self = [self init];
    if (self) {
        [self setDestinationCoordinates:coordinates];
    }
    return self;
}

- (instancetype)initWithCoordinates:(CLLocationCoordinate2D)coordinates
                      arrivalRadius:(NSInteger)arrivalRadius {
    self = [self initWithCoordinates:coordinates];
    if (self) {
        _arrivalRadius = arrivalRadius;
    }
    return self;
}

#pragma mark - Coordinate Accessors

- (BOOL)hasCoordinates {
    return _hasCoordinates;
}

- (void)setDestinationCoordinates:(CLLocationCoordinate2D)coordinates {
    _coordinates = coordinates;
    _hasCoordinates = CLLocationCoordinate2DIsValid(coordinates);
}

#pragma mark - Serialization

+ (RadarTripLeg *_Nullable)legFromDictionary:(NSDictionary *_Nullable)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    RadarTripLeg *leg = [[RadarTripLeg alloc] init];
    
    // Handle nested destination object structure
    id destinationObj = dict[kDestination];
    if (destinationObj && [destinationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *destination = (NSDictionary *)destinationObj;
        
        // Geofence by tag + externalId
        leg.destinationGeofenceTag = destination[kDestinationGeofenceTag];
        leg.destinationGeofenceExternalId = destination[kDestinationGeofenceExternalId];
        
        // Geofence by ID
        id geofenceIdObj = destination[kDestinationGeofenceId];
        if (geofenceIdObj && [geofenceIdObj isKindOfClass:[NSString class]]) {
            leg.destinationGeofenceId = (NSString *)geofenceIdObj;
        }
        
        // Address
        id addressObj = destination[kAddress];
        if (addressObj && [addressObj isKindOfClass:[NSString class]]) {
            leg.address = (NSString *)addressObj;
        }
        
        // Coordinates [lng, lat]
        id coordinatesObj = destination[kCoordinates];
        if (coordinatesObj && [coordinatesObj isKindOfClass:[NSArray class]]) {
            NSArray *coordArray = (NSArray *)coordinatesObj;
            if (coordArray.count >= 2) {
                double lng = [coordArray[0] doubleValue];
                double lat = [coordArray[1] doubleValue];
                [leg setDestinationCoordinates:CLLocationCoordinate2DMake(lat, lng)];
            }
        }
        
        // Arrival radius
        id arrivalRadiusObj = destination[kArrivalRadius];
        if (arrivalRadiusObj && [arrivalRadiusObj isKindOfClass:[NSNumber class]]) {
            leg.arrivalRadius = [(NSNumber *)arrivalRadiusObj integerValue];
        }
    } else {
        // Also support flat structure for flexibility
        leg.destinationGeofenceTag = dict[kDestinationGeofenceTag];
        leg.destinationGeofenceExternalId = dict[kDestinationGeofenceExternalId];
    }
    
    id stopDurationObj = dict[kStopDuration];
    if (stopDurationObj && [stopDurationObj isKindOfClass:[NSNumber class]]) {
        leg.stopDuration = [(NSNumber *)stopDurationObj integerValue];
    }
    
    id metadataObj = dict[kMetadata];
    if (metadataObj && [metadataObj isKindOfClass:[NSDictionary class]]) {
        leg.metadata = (NSDictionary *)metadataObj;
    }
    
    return leg;
}

+ (NSArray<RadarTripLeg *> *_Nullable)legsFromArray:(NSArray *_Nullable)array {
    if (!array || ![array isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray<RadarTripLeg *> *legs = [NSMutableArray new];
    for (id obj in array) {
        RadarTripLeg *leg = [RadarTripLeg legFromDictionary:obj];
        if (leg) {
            [legs addObject:leg];
        }
    }
    
    return legs.count > 0 ? [legs copy] : nil;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    // Create nested destination structure to match API format
    NSMutableDictionary *destination = [NSMutableDictionary new];
    
    // Geofence by tag + externalId
    if (self.destinationGeofenceTag) {
        destination[kDestinationGeofenceTag] = self.destinationGeofenceTag;
    }
    if (self.destinationGeofenceExternalId) {
        destination[kDestinationGeofenceExternalId] = self.destinationGeofenceExternalId;
    }
    
    // Geofence by ID
    if (self.destinationGeofenceId) {
        destination[kDestinationGeofenceId] = self.destinationGeofenceId;
    }
    
    // Address
    if (self.address) {
        destination[kAddress] = self.address;
    }
    
    // Coordinates [lng, lat]
    if (self.hasCoordinates) {
        destination[kCoordinates] = @[@(self.coordinates.longitude), @(self.coordinates.latitude)];
        if (self.arrivalRadius > 0) {
            destination[kArrivalRadius] = @(self.arrivalRadius);
        }
    }
    
    if (destination.count > 0) {
        dict[kDestination] = destination;
    }
    
    if (self.stopDuration > 0) {
        dict[kStopDuration] = @(self.stopDuration);
    }
    
    if (self.metadata) {
        dict[kMetadata] = self.metadata;
    }
    
    return dict;
}

+ (NSArray<NSDictionary *> *_Nullable)arrayForLegs:(NSArray<RadarTripLeg *> *_Nullable)legs {
    if (!legs || legs.count == 0) {
        return nil;
    }
    
    NSMutableArray<NSDictionary *> *array = [NSMutableArray new];
    for (RadarTripLeg *leg in legs) {
        [array addObject:[leg dictionaryValue]];
    }
    
    return [array copy];
}

- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }
    
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[RadarTripLeg class]]) {
        return NO;
    }
    
    RadarTripLeg *other = (RadarTripLeg *)object;
    
    // Compare geofence tag
    BOOL geofenceTagEqual = (!self.destinationGeofenceTag && !other.destinationGeofenceTag) ||
                            (self.destinationGeofenceTag && other.destinationGeofenceTag && 
                             [self.destinationGeofenceTag isEqualToString:other.destinationGeofenceTag]);
    
    // Compare geofence external ID
    BOOL geofenceExternalIdEqual = (!self.destinationGeofenceExternalId && !other.destinationGeofenceExternalId) ||
                                   (self.destinationGeofenceExternalId && other.destinationGeofenceExternalId && 
                                    [self.destinationGeofenceExternalId isEqualToString:other.destinationGeofenceExternalId]);
    
    // Compare geofence ID
    BOOL geofenceIdEqual = (!self.destinationGeofenceId && !other.destinationGeofenceId) ||
                           (self.destinationGeofenceId && other.destinationGeofenceId && 
                            [self.destinationGeofenceId isEqualToString:other.destinationGeofenceId]);
    
    // Compare address
    BOOL addressEqual = (!self.address && !other.address) ||
                        (self.address && other.address && [self.address isEqualToString:other.address]);
    
    // Compare coordinates
    BOOL coordinatesEqual = (self.hasCoordinates == other.hasCoordinates) &&
                            (!self.hasCoordinates || 
                             (self.coordinates.latitude == other.coordinates.latitude && 
                              self.coordinates.longitude == other.coordinates.longitude));
    
    // Compare metadata
    BOOL metadataEqual = (!self.metadata && !other.metadata) ||
                         (self.metadata && other.metadata && [self.metadata isEqualToDictionary:other.metadata]);
    
    return geofenceTagEqual &&
           geofenceExternalIdEqual &&
           geofenceIdEqual &&
           addressEqual &&
           coordinatesEqual &&
           self.arrivalRadius == other.arrivalRadius &&
           self.stopDuration == other.stopDuration &&
           metadataEqual;
}

@end

