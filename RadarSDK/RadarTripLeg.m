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
static NSString *const kType = @"type";
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

#pragma mark - Destination Type String Conversion

+ (NSString *)stringForDestinationType:(RadarTripLegDestinationType)destinationType {
    switch (destinationType) {
        case RadarTripLegDestinationTypeGeofence:
            return @"geofence";
        case RadarTripLegDestinationTypeAddress:
            return @"address";
        case RadarTripLegDestinationTypeCoordinates:
            return @"coordinates";
        default:
            return @"unknown";
    }
}

+ (RadarTripLegDestinationType)destinationTypeForString:(NSString *)string {
    if ([string isEqualToString:@"geofence"]) {
        return RadarTripLegDestinationTypeGeofence;
    } else if ([string isEqualToString:@"address"]) {
        return RadarTripLegDestinationTypeAddress;
    } else if ([string isEqualToString:@"coordinates"]) {
        return RadarTripLegDestinationTypeCoordinates;
    }
    return RadarTripLegDestinationTypeUnknown;
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
        _destinationType = RadarTripLegDestinationTypeUnknown;
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
        _destinationType = RadarTripLegDestinationTypeGeofence;
    }
    return self;
}

- (instancetype)initWithDestinationGeofenceId:(NSString *_Nonnull)destinationGeofenceId {
    self = [self init];
    if (self) {
        _destinationGeofenceId = destinationGeofenceId;
        _destinationType = RadarTripLegDestinationTypeGeofence;
    }
    return self;
}

- (instancetype)initWithAddress:(NSString *_Nonnull)address {
    self = [self init];
    if (self) {
        _address = address;
        _destinationType = RadarTripLegDestinationTypeAddress;
    }
    return self;
}

- (instancetype)initWithCoordinates:(CLLocationCoordinate2D)coordinates {
    self = [self init];
    if (self) {
        _coordinates = coordinates;
        _hasCoordinates = CLLocationCoordinate2DIsValid(coordinates);
        _destinationType = RadarTripLegDestinationTypeCoordinates;
    }
    return self;
}

#pragma mark - Computed Properties

- (BOOL)hasCoordinates {
    return _hasCoordinates;
}

#pragma mark - Coordinate Setter

- (void)setCoordinates:(CLLocationCoordinate2D)coordinates {
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

    // Handle destination object
    id destinationObj = dict[kDestination];
    if (destinationObj && [destinationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *destination = (NSDictionary *)destinationObj;

        // Read destination type if present (server response format)
        id typeObj = destination[kType];
        if (typeObj && [typeObj isKindOfClass:[NSString class]]) {
            leg->_destinationType = [RadarTripLeg destinationTypeForString:(NSString *)typeObj];
        }

        // Server response format: type-driven parsing of source
        id sourceObj = destination[kSource];
        if (sourceObj && [sourceObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *source = (NSDictionary *)sourceObj;
            id dataObj = source[kData];

            switch (leg->_destinationType) {
                case RadarTripLegDestinationTypeGeofence: {
                    id geofenceObj = source[kGeofence];
                    if (geofenceObj && [geofenceObj isKindOfClass:[NSString class]]) {
                        leg.destinationGeofenceId = (NSString *)geofenceObj;
                    }
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
                    break;
                }
                case RadarTripLegDestinationTypeAddress: {
                    if (dataObj && [dataObj isKindOfClass:[NSString class]]) {
                        leg.address = (NSString *)dataObj;
                    }
                    break;
                }
                case RadarTripLegDestinationTypeCoordinates:
                    // source.data is [lat, lng] which is redundant with location (GeoJSON), parsed below
                case RadarTripLegDestinationTypeUnknown:
                    break;
            }
        } else {
            // Request format: flat fields in destination
            id tagObj = destination[kDestinationGeofenceTag];
            if (tagObj && [tagObj isKindOfClass:[NSString class]]) {
                leg.destinationGeofenceTag = (NSString *)tagObj;
            }
            id externalIdObj = destination[kDestinationGeofenceExternalId];
            if (externalIdObj && [externalIdObj isKindOfClass:[NSString class]]) {
                leg.destinationGeofenceExternalId = (NSString *)externalIdObj;
            }
            id geofenceIdObj = destination[kDestinationGeofenceId];
            if (geofenceIdObj && [geofenceIdObj isKindOfClass:[NSString class]]) {
                leg.destinationGeofenceId = (NSString *)geofenceIdObj;
            }
            id addressObj = destination[kAddress];
            if (addressObj && [addressObj isKindOfClass:[NSString class]]) {
                leg.address = (NSString *)addressObj;
            }
            id coordinatesObj = destination[kCoordinates];
            if (coordinatesObj && [coordinatesObj isKindOfClass:[NSArray class]]) {
                NSArray *coordArray = (NSArray *)coordinatesObj;
                if (coordArray.count >= 2) {
                    double lng = [coordArray[0] doubleValue];
                    double lat = [coordArray[1] doubleValue];
                    leg.coordinates = CLLocationCoordinate2DMake(lat, lng);
                }
            }
        }

        // GeoJSON location (present in all server response types)
        id locationObj = destination[kLocation];
        if (locationObj && [locationObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *location = (NSDictionary *)locationObj;
            id coordinatesObj = location[kCoordinates];
            if (coordinatesObj && [coordinatesObj isKindOfClass:[NSArray class]]) {
                NSArray *coordArray = (NSArray *)coordinatesObj;
                if (coordArray.count >= 2) {
                    double lng = [coordArray[0] doubleValue];
                    double lat = [coordArray[1] doubleValue];
                    leg.coordinates = CLLocationCoordinate2DMake(lat, lng);
                }
            }
        }

        // Arrival radius
        id arrivalRadiusObj = destination[kArrivalRadius];
        if (arrivalRadiusObj && [arrivalRadiusObj isKindOfClass:[NSNumber class]]) {
            leg.arrivalRadius = [(NSNumber *)arrivalRadiusObj integerValue];
        }

        // Infer destination type if not explicitly provided (request format round-trip)
        if (leg->_destinationType == RadarTripLegDestinationTypeUnknown) {
            if ((leg.destinationGeofenceTag && leg.destinationGeofenceExternalId) || leg.destinationGeofenceId) {
                leg->_destinationType = RadarTripLegDestinationTypeGeofence;
            } else if (leg.address) {
                leg->_destinationType = RadarTripLegDestinationTypeAddress;
            } else if (leg.hasCoordinates) {
                leg->_destinationType = RadarTripLegDestinationTypeCoordinates;
            }
        }
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

    // Create nested destination structure to match API request format
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

    if (self.destinationType != other.destinationType) {
        return NO;
    }

    if (self.status != other.status) {
        return NO;
    }

    if (self.stopDuration != other.stopDuration) {
        return NO;
    }

    if (self.arrivalRadius != other.arrivalRadius) {
        return NO;
    }

    if (self.hasCoordinates != other.hasCoordinates) {
        return NO;
    }

    if (self.hasCoordinates &&
        (self.coordinates.latitude != other.coordinates.latitude ||
         self.coordinates.longitude != other.coordinates.longitude)) {
        return NO;
    }

    // Compare nullable string properties
    if (![self isNullableString:self._id equalTo:other._id]) {
        return NO;
    }
    if (![self isNullableString:self.destinationGeofenceTag equalTo:other.destinationGeofenceTag]) {
        return NO;
    }
    if (![self isNullableString:self.destinationGeofenceExternalId equalTo:other.destinationGeofenceExternalId]) {
        return NO;
    }
    if (![self isNullableString:self.destinationGeofenceId equalTo:other.destinationGeofenceId]) {
        return NO;
    }
    if (![self isNullableString:self.address equalTo:other.address]) {
        return NO;
    }

    if (self.metadata != other.metadata && ![self.metadata isEqualToDictionary:other.metadata]) {
        return NO;
    }

    return YES;
}

- (BOOL)isNullableString:(NSString *_Nullable)a equalTo:(NSString *_Nullable)b {
    if (!a && !b) {
        return YES;
    }
    return [a isEqualToString:b];
}

@end
