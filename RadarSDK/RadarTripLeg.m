//
//  RadarTripLeg.m
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "Include/RadarTripLeg.h"
#import "RadarUtils.h"

@implementation RadarTripLeg {
    BOOL _hasCoordinates;
}

// Request/Response field keys
static NSString *const kId = @"_id";
static NSString *const kStatus = @"status";
static NSString *const kCreatedAt = @"createdAt";
static NSString *const kUpdatedAt = @"updatedAt";
static NSString *const kDestination = @"destination";
static NSString *const kDestinationGeofenceTag = @"destinationGeofenceTag";
static NSString *const kDestinationGeofenceExternalId = @"destinationGeofenceExternalId";
static NSString *const kDestinationGeofenceId = @"destinationGeofenceId";
static NSString *const kAddress = @"address";
static NSString *const kCoordinates = @"coordinates";
static NSString *const kLocation = @"location";
static NSString *const kSource = @"source";
static NSString *const kData = @"data";
static NSString *const kTag = @"tag";
static NSString *const kExternalId = @"externalId";
static NSString *const kGeofence = @"geofence";
static NSString *const kArrivalRadius = @"arrivalRadius";
static NSString *const kStopDuration = @"stopDuration";
static NSString *const kMetadata = @"metadata";
static NSString *const kEta = @"eta";
static NSString *const kDuration = @"duration";
static NSString *const kDistance = @"distance";

#pragma mark - Status String Conversion

+ (NSString *)stringForStatus:(RadarTripLegStatus)status {
    switch (status) {
        case RadarTripLegStatusPending:
            return @"pending";
        case RadarTripLegStatusStarted:
            return @"started";
        case RadarTripLegStatusApproaching:
            return @"approaching";
        case RadarTripLegStatusArrived:
            return @"arrived";
        case RadarTripLegStatusCompleted:
            return @"completed";
        case RadarTripLegStatusCanceled:
            return @"canceled";
        case RadarTripLegStatusExpired:
            return @"expired";
        default:
            return @"unknown";
    }
}

+ (RadarTripLegStatus)statusForString:(NSString *)string {
    if ([string isEqualToString:@"pending"]) {
        return RadarTripLegStatusPending;
    } else if ([string isEqualToString:@"started"]) {
        return RadarTripLegStatusStarted;
    } else if ([string isEqualToString:@"approaching"]) {
        return RadarTripLegStatusApproaching;
    } else if ([string isEqualToString:@"arrived"]) {
        return RadarTripLegStatusArrived;
    } else if ([string isEqualToString:@"completed"]) {
        return RadarTripLegStatusCompleted;
    } else if ([string isEqualToString:@"canceled"]) {
        return RadarTripLegStatusCanceled;
    } else if ([string isEqualToString:@"expired"]) {
        return RadarTripLegStatusExpired;
    }
    return RadarTripLegStatusUnknown;
}

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        _stopDuration = 0;
        _arrivalRadius = 0;
        _hasCoordinates = NO;
        _coordinates = kCLLocationCoordinate2DInvalid;
        _status = RadarTripLegStatusUnknown;
        _etaDuration = 0;
        _etaDistance = 0;
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
    
    // Parse response fields (_id, status, createdAt, updatedAt)
    id idObj = dict[kId];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        leg->__id = (NSString *)idObj;
    }
    
    id statusObj = dict[kStatus];
    if (statusObj && [statusObj isKindOfClass:[NSString class]]) {
        leg->_status = [RadarTripLeg statusForString:(NSString *)statusObj];
    }
    
    id createdAtObj = dict[kCreatedAt];
    if (createdAtObj && [createdAtObj isKindOfClass:[NSString class]]) {
        leg->_createdAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)createdAtObj];
    }
    
    id updatedAtObj = dict[kUpdatedAt];
    if (updatedAtObj && [updatedAtObj isKindOfClass:[NSString class]]) {
        leg->_updatedAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)updatedAtObj];
    }
    
    // Parse ETA object
    id etaObj = dict[kEta];
    if (etaObj && [etaObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *eta = (NSDictionary *)etaObj;
        id durationObj = eta[kDuration];
        if (durationObj && [durationObj isKindOfClass:[NSNumber class]]) {
            leg->_etaDuration = [(NSNumber *)durationObj floatValue];
        }
        id distanceObj = eta[kDistance];
        if (distanceObj && [distanceObj isKindOfClass:[NSNumber class]]) {
            leg->_etaDistance = [(NSNumber *)distanceObj floatValue];
        }
    }
    
    // Handle nested destination object structure
    id destinationObj = dict[kDestination];
    if (destinationObj && [destinationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *destination = (NSDictionary *)destinationObj;
        
        // Check for server response format with source.data structure
        id sourceObj = destination[kSource];
        if (sourceObj && [sourceObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *source = (NSDictionary *)sourceObj;
            
            // Get geofence ID from source.geofence
            id geofenceObj = source[kGeofence];
            if (geofenceObj && [geofenceObj isKindOfClass:[NSString class]]) {
                leg.destinationGeofenceId = (NSString *)geofenceObj;
            }
            
            // Get tag and externalId from source.data
            id dataObj = source[kData];
            if (dataObj && [dataObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *data = (NSDictionary *)dataObj;
                id tagObj = data[kTag];
                if (tagObj && [tagObj isKindOfClass:[NSString class]]) {
                    leg.destinationGeofenceTag = (NSString *)tagObj;
                }
                id externalIdObj = data[kExternalId];
                if (externalIdObj && [externalIdObj isKindOfClass:[NSString class]]) {
                    leg.destinationGeofenceExternalId = (NSString *)externalIdObj;
                }
            }
        } else {
            // Request format: direct fields in destination
            // Geofence by tag + externalId
            id tagObj = destination[kDestinationGeofenceTag];
            if (tagObj && [tagObj isKindOfClass:[NSString class]]) {
                leg.destinationGeofenceTag = (NSString *)tagObj;
            }
            id externalIdObj = destination[kDestinationGeofenceExternalId];
            if (externalIdObj && [externalIdObj isKindOfClass:[NSString class]]) {
                leg.destinationGeofenceExternalId = (NSString *)externalIdObj;
            }
            
            // Geofence by ID
            id geofenceIdObj = destination[kDestinationGeofenceId];
            if (geofenceIdObj && [geofenceIdObj isKindOfClass:[NSString class]]) {
                leg.destinationGeofenceId = (NSString *)geofenceIdObj;
            }
            
            // Request format: coordinates directly in destination
            id coordinatesObj = destination[kCoordinates];
            if (coordinatesObj && [coordinatesObj isKindOfClass:[NSArray class]]) {
                NSArray *coordArray = (NSArray *)coordinatesObj;
                if (coordArray.count >= 2) {
                    double lng = [coordArray[0] doubleValue];
                    double lat = [coordArray[1] doubleValue];
                    [leg setDestinationCoordinates:CLLocationCoordinate2DMake(lat, lng)];
                }
            }
        }
        
        // Address
        id addressObj = destination[kAddress];
        if (addressObj && [addressObj isKindOfClass:[NSString class]]) {
            leg.address = (NSString *)addressObj;
        }
        
        // Response format: location.coordinates (GeoJSON)
        id locationObj = destination[kLocation];
        if (locationObj && [locationObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *location = (NSDictionary *)locationObj;
            id coordinatesObj = location[kCoordinates];
            if (coordinatesObj && [coordinatesObj isKindOfClass:[NSArray class]]) {
                NSArray *coordArray = (NSArray *)coordinatesObj;
                if (coordArray.count >= 2) {
                    double lng = [coordArray[0] doubleValue];
                    double lat = [coordArray[1] doubleValue];
                    [leg setDestinationCoordinates:CLLocationCoordinate2DMake(lat, lng)];
                }
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
    
    // Include response fields if present
    if (self._id) {
        dict[kId] = self._id;
    }
    if (self.status != RadarTripLegStatusUnknown) {
        dict[kStatus] = [RadarTripLeg stringForStatus:self.status];
    }
    if (self.createdAt) {
        dict[kCreatedAt] = [RadarUtils.isoDateFormatter stringFromDate:self.createdAt];
    }
    if (self.updatedAt) {
        dict[kUpdatedAt] = [RadarUtils.isoDateFormatter stringFromDate:self.updatedAt];
    }
    
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
    
    // Include ETA if present (from server response)
    if (self.etaDuration > 0 || self.etaDistance > 0) {
        NSMutableDictionary *eta = [NSMutableDictionary new];
        if (self.etaDuration > 0) {
            eta[kDuration] = @(self.etaDuration);
        }
        if (self.etaDistance > 0) {
            eta[kDistance] = @(self.etaDistance);
        }
        dict[kEta] = eta;
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
    
    // Compare _id (if both have IDs, compare them; otherwise skip)
    BOOL idEqual = (!self._id && !other._id) ||
                   (self._id && other._id && [self._id isEqualToString:other._id]);
    
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
    
    return idEqual &&
           geofenceTagEqual &&
           geofenceExternalIdEqual &&
           geofenceIdEqual &&
           addressEqual &&
           coordinatesEqual &&
           self.arrivalRadius == other.arrivalRadius &&
           self.stopDuration == other.stopDuration &&
           self.status == other.status &&
           metadataEqual;
}

@end

