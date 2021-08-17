//
//  RadarTripOptions.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarTripOptions.h"

@implementation RadarTripOptions

static NSString *const kExternalId = @"externalId";
static NSString *const kMetadata = @"metadata";
static NSString *const kDestinationGeofenceTag = @"destinationGeofenceTag";
static NSString *const kDestinationGeofenceExternalId = @"destinationGeofenceExternalId";
static NSString *const kMode = @"mode";

- (instancetype)initWithExternalId:(NSString *_Nonnull)externalId {
    self = [super init];
    if (self) {
        _externalId = externalId;
        _mode = RadarRouteModeCar;
    }
    return self;
}

+ (RadarTripOptions *)tripOptionsFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return nil;
    }

    RadarTripOptions *options = [[RadarTripOptions alloc] initWithExternalId:dict[kExternalId]];
    options.metadata = dict[kMetadata];
    options.destinationGeofenceTag = dict[kDestinationGeofenceTag];
    options.destinationGeofenceExternalId = dict[kDestinationGeofenceExternalId];
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
    return options;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[kExternalId] = self.externalId;
    dict[kMetadata] = self.metadata;
    dict[kDestinationGeofenceTag] = self.destinationGeofenceTag;
    dict[kDestinationGeofenceExternalId] = self.destinationGeofenceExternalId;
    dict[kMode] = [Radar stringForMode:self.mode];
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
           self.mode == options.mode;
}

@end
