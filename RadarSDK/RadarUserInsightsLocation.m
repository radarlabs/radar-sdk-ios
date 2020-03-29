//
//  RadarUserInsightsLocation.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUserInsightsLocation.h"
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
    RadarCoordinate *location;
    RadarUserInsightsLocationConfidence confidence = RadarUserInsightsLocationConfidenceNone;
    NSDate *updatedAt;
    RadarRegion *country;
    RadarRegion *state;
    RadarRegion *dma;
    RadarRegion *postalCode;

    id typeObj = dict[@"type"];
    if (typeObj && [typeObj isKindOfClass:[NSString class]]) {
        NSString *typeStr = (NSString *)typeObj;

        if ([typeStr isEqualToString:@"home"]) {
            type = RadarUserInsightsLocationTypeHome;
        } else if ([typeStr isEqualToString:@"office"]) {
            type = RadarUserInsightsLocationTypeOffice;
        }
    }

    id locationObj = dict[@"location"];
    if (locationObj && [locationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *locationDict = (NSDictionary *)locationObj;

        id locationCoordinatesObj = locationDict[@"coordinates"];
        if (!locationCoordinatesObj || ![locationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }

        NSArray *locationCoordinatesArr = (NSArray *)locationCoordinatesObj;
        if (locationCoordinatesArr.count != 2) {
            return nil;
        }

        id locationCoordinatesLongitudeObj = locationCoordinatesArr[0];
        id locationCoordinatesLatitudeObj = locationCoordinatesArr[1];
        if (!locationCoordinatesLongitudeObj || !locationCoordinatesLatitudeObj || ![locationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] ||
            ![locationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        NSNumber *locationCoordinatesLongitudeNumber = (NSNumber *)locationCoordinatesLongitudeObj;
        NSNumber *locationCoordinatesLatitudeNumber = (NSNumber *)locationCoordinatesLatitudeObj;

        float locationCoordinatesLongitudeFloat = [locationCoordinatesLongitudeNumber floatValue];
        float locationCoordinatesLatitudeFloat = [locationCoordinatesLatitudeNumber floatValue];

        location = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(locationCoordinatesLatitudeFloat, locationCoordinatesLongitudeFloat)];
    }

    id confidenceObj = dict[@"confidence"];
    if (confidenceObj && [confidenceObj isKindOfClass:[NSNumber class]]) {
        NSNumber *confidenceNumber = (NSNumber *)confidenceObj;
        int userInsightsLocationConfidenceInt = [confidenceNumber intValue];

        if (userInsightsLocationConfidenceInt == 3) {
            confidence = RadarUserInsightsLocationConfidenceHigh;
        } else if (userInsightsLocationConfidenceInt == 2) {
            confidence = RadarUserInsightsLocationConfidenceMedium;
        } else if (userInsightsLocationConfidenceInt == 1) {
            confidence = RadarUserInsightsLocationConfidenceLow;
        }
    }

    id updatedAtObj = dict[@"updatedAt"];
    if (updatedAtObj && [updatedAtObj isKindOfClass:[NSString class]]) {
        NSString *userInsightsLocationUpdatedAtStr = (NSString *)updatedAtObj;

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];

        updatedAt = [dateFormatter dateFromString:userInsightsLocationUpdatedAtStr];
    }

    id countryObj = dict[@"country"];
    country = [[RadarRegion alloc] initWithObject:countryObj];

    id stateObj = dict[@"state"];
    state = [[RadarRegion alloc] initWithObject:stateObj];

    id dmaObj = dict[@"dma"];
    dma = [[RadarRegion alloc] initWithObject:dmaObj];

    id postalCodeObj = dict[@"postalCode"];
    postalCode = [[RadarRegion alloc] initWithObject:postalCodeObj];

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
