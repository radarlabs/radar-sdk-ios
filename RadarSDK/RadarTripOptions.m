//
//  RadarTripOptions.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarTripOptions.h"
#import "RadarUtils.h"

@implementation RadarTripOptions

static NSString *const kExternalId = @"externalId";
static NSString *const kMetadata = @"metadata";
static NSString *const kDestinationGeofenceTag = @"destinationGeofenceTag";
static NSString *const kDestinationGeofenceExternalId = @"destinationGeofenceExternalId";
static NSString *const kMode = @"mode";
static NSString *const kScheduledArrivalAt = @"scheduledArrivalAt";
static NSString *const kApproachingThreshold = @"approachingThreshold";

- (instancetype)initWithExternalId:(NSString *_Nonnull)externalId
            destinationGeofenceTag:(NSString *_Nullable)destinationGeofenceTag
     destinationGeofenceExternalId:(NSString *_Nullable)destinationGeofenceExternalId {
    self = [super init];
    if (self) {
        _externalId = externalId;
        _destinationGeofenceTag = destinationGeofenceTag;
        _destinationGeofenceExternalId = destinationGeofenceExternalId;
        _mode = RadarRouteModeCar;
    }
    return self;
}

- (instancetype)initWithExternalId:(NSString *_Nonnull)externalId
            destinationGeofenceTag:(NSString *_Nullable)destinationGeofenceTag
     destinationGeofenceExternalId:(NSString *_Nullable)destinationGeofenceExternalId
                scheduledArrivalAt:(NSDate *_Nullable)scheduledArrivalAt {
    self = [self initWithExternalId:externalId destinationGeofenceTag:destinationGeofenceTag destinationGeofenceExternalId:destinationGeofenceExternalId];

    if (self) {
        _scheduledArrivalAt = scheduledArrivalAt;
    }

    return self;
}

+ (RadarTripOptions *)tripOptionsFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return nil;
    }

    NSDate *scheduledArrivalAt;
    NSObject *scheduledArrivalAtObj = dict[kScheduledArrivalAt];
    if (scheduledArrivalAtObj) {
        if ([scheduledArrivalAtObj isKindOfClass:[NSString class]]) {
            scheduledArrivalAt = [RadarUtils.isoDateFormatter dateFromString:(NSString *)scheduledArrivalAtObj];
        } else if ([scheduledArrivalAtObj isKindOfClass:[NSDate class]]) {
            scheduledArrivalAt = (NSDate *)scheduledArrivalAtObj;
        } else if ([scheduledArrivalAtObj isKindOfClass:[NSNumber class]]) {
            scheduledArrivalAt = [NSDate dateWithTimeIntervalSince1970:([(NSNumber *)scheduledArrivalAtObj doubleValue] / 1000.0)];
        }
    }

    RadarTripOptions *options = [[RadarTripOptions alloc] initWithExternalId:dict[kExternalId]
                                                      destinationGeofenceTag:dict[kDestinationGeofenceTag]
                                               destinationGeofenceExternalId:dict[kDestinationGeofenceExternalId]
                                                          scheduledArrivalAt:scheduledArrivalAt];
    options.metadata = dict[kMetadata];
    NSString *modeStr = dict[kMode];
    if ([modeStr isEqualToString:@"foot"]) {
        options.mode = RadarRouteModeFoot;
    } else if ([modeStr isEqualToString:@"bike"]) {
        options.mode = RadarRouteModeBike;
    } else if ([modeStr isEqualToString:@"truck"]) {
        options.mode = RadarRouteModeTruck;
    } else if ([modeStr isEqualToString:@"motorbike"]) {
        options.mode = RadarRouteModeMotorbike;
    } else {
        options.mode = RadarRouteModeCar;
    }
    options.approachingThreshold = [dict[kApproachingThreshold] intValue];
    return options;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[kExternalId] = self.externalId;
    dict[kMetadata] = self.metadata;
    dict[kDestinationGeofenceTag] = self.destinationGeofenceTag;
    dict[kDestinationGeofenceExternalId] = self.destinationGeofenceExternalId;
    dict[kMode] = [Radar stringForMode:self.mode];
    dict[kScheduledArrivalAt] = self.scheduledArrivalAt;
    if (self.approachingThreshold && self.approachingThreshold > 0) {
        dict[kApproachingThreshold] = @(self.approachingThreshold);
    }
    return dict;
}

- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }

    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[RadarTripOptions class]]) {
        return NO;
    }

    RadarTripOptions *options = (RadarTripOptions *)object;

    return [self.externalId isEqualToString:options.externalId] &&
           ((!self.metadata && !options.metadata) || (self.metadata != nil && options.metadata != nil && [self.metadata isEqualToDictionary:options.metadata])) &&
           ((!self.destinationGeofenceTag && !options.destinationGeofenceTag) ||
            (self.destinationGeofenceTag != nil && options.destinationGeofenceTag != nil && [self.destinationGeofenceTag isEqualToString:options.destinationGeofenceTag])) &&
           ((!self.destinationGeofenceExternalId && !options.destinationGeofenceExternalId) ||
            (self.destinationGeofenceExternalId != nil && options.destinationGeofenceExternalId != nil &&
             [self.destinationGeofenceExternalId isEqualToString:options.destinationGeofenceExternalId])) &&
           ((!self.scheduledArrivalAt && !options.scheduledArrivalAt) ||
            (self.scheduledArrivalAt != nil && options.scheduledArrivalAt != nil && [self.scheduledArrivalAt isEqualToDate:options.scheduledArrivalAt])) &&
           self.mode == options.mode && ((!self.approachingThreshold && !options.approachingThreshold) || (self.approachingThreshold == options.approachingThreshold));
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [RadarTripOptions tripOptionsFromDictionary:[coder decodeObjectForKey:@"dictionaryValue"]];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self dictionaryValue] forKey:@"dictionaryValue"];
}

@end
