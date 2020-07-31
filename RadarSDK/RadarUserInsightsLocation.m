//
//  RadarUserInsightsLocation.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUserInsightsLocation.h"
#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"
#import "RadarRegion+Internal.h"
#import "RadarUserInsightsLocation+Internal.h"
#import "RadarUtils.h"

@implementation RadarUserInsightsLocation

- (instancetype _Nullable)initWithType:(RadarUserInsightsLocationType)type
                              location:(RadarCoordinate *_Nullable)location
                            confidence:(RadarUserInsightsLocationConfidence)confidence
                             updatedAt:(NSDate *)updatedAt
                               country:(RadarRegion *_Nullable)country
                                 state:(RadarRegion *_Nullable)state
                                   dma:(RadarRegion *_Nullable)dma
                            postalCode:(RadarRegion *_Nullable)postalCode {
    self = [super init];
    if (self) {
        _type = type;
        _location = location;
        _confidence = confidence;
        _updatedAt = updatedAt;
        _country = country;
        _state = state;
        _dma = dma;
        _postalCode = postalCode;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    RadarUserInsightsLocationType type = RadarUserInsightsLocationTypeUnknown;
    NSString *typeStr = [dict radar_stringForKey:@"type"];
    if ([typeStr isEqualToString:@"home"]) {
        type = RadarUserInsightsLocationTypeHome;
    } else if ([typeStr isEqualToString:@"office"]) {
        type = RadarUserInsightsLocationTypeOffice;
    }

    RadarCoordinate *location = [[RadarCoordinate alloc] initWithObject:dict[@"location"]];

    NSNumber *confidenceNumber = [dict radar_numberForKey:@"confidence"];
    RadarUserInsightsLocationConfidence confidence = RadarUserInsightsLocationConfidenceNone;
    if (confidenceNumber) {
        int userInsightsLocationConfidenceInt = [confidenceNumber intValue];
        if (userInsightsLocationConfidenceInt == 3) {
            confidence = RadarUserInsightsLocationConfidenceHigh;
        } else if (userInsightsLocationConfidenceInt == 2) {
            confidence = RadarUserInsightsLocationConfidenceMedium;
        } else if (userInsightsLocationConfidenceInt == 1) {
            confidence = RadarUserInsightsLocationConfidenceLow;
        }
    }

    NSDate *updatedAt = [dict radar_dateForKey:@"updatedAt"];

    RadarRegion *country = [[RadarRegion alloc] initWithObject:dict[@"country"]];
    RadarRegion *state = [[RadarRegion alloc] initWithObject:dict[@"state"]];
    RadarRegion *dma = [[RadarRegion alloc] initWithObject:dict[@"dma"]];
    RadarRegion *postalCode = [[RadarRegion alloc] initWithObject:dict[@"postalCode"]];

    if (updatedAt) {
        return [[RadarUserInsightsLocation alloc] initWithType:type
                                                      location:location
                                                    confidence:confidence
                                                     updatedAt:updatedAt
                                                       country:country
                                                         state:state
                                                           dma:dma
                                                    postalCode:postalCode];
    }

    return nil;
}

+ (NSString *)stringForType:(RadarUserInsightsLocationType)type {
    switch (type) {
    case RadarUserInsightsLocationTypeHome:
        return @"home";
    case RadarUserInsightsLocationTypeOffice:
        return @"office";
    default:
        return nil;
    }
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    if (self.type) {
        NSString *type = [RadarUserInsightsLocation stringForType:self.type];
        [dict setValue:type forKey:@"type"];
    }
    if (self.location) {
        NSDictionary *locationDict = [self.location dictionaryValue];
        [dict setValue:locationDict forKey:@"location"];
    }
    NSNumber *confidence = @(self.confidence);
    [dict setValue:confidence forKey:@"confidence"];
    return dict;
}

@end
