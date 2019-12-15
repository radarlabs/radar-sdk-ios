//
//  RadarUserInsightsLocation.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUserInsightsLocation.h"
#import "RadarUserInsightsLocation+Internal.h"
#import "RadarRegion+Internal.h"

@implementation RadarUserInsightsLocation

- (instancetype _Nullable)initWithType:(RadarUserInsightsLocationType)type location:(CLLocation *)location confidence:(RadarUserInsightsLocationConfidence)confidence updatedAt:(NSDate *)updatedAt country:(RadarRegion * _Nullable)country state:(RadarRegion * _Nullable)state dma:(RadarRegion * _Nullable)dma postalCode:(RadarRegion * _Nullable)postalCode {
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
    
    NSDictionary *userInsightsLocationDict = (NSDictionary *)object;
    
    RadarUserInsightsLocationType userInsightsLocationType = RadarUserInsightsLocationTypeUnknown;
    CLLocation *userInsightsLocationLocation;
    RadarUserInsightsLocationConfidence userInsightsLocationConfidence = RadarUserInsightsLocationConfidenceNone;
    NSDate *userInsightsLocationUpdatedAt;
    RadarRegion *country;
    RadarRegion *state;
    RadarRegion *dma;
    RadarRegion *postalCode;
    
    id userInsightsLocationTypeObj = userInsightsLocationDict[@"type"];
    if (userInsightsLocationTypeObj && [userInsightsLocationTypeObj isKindOfClass:[NSString class]]) {
        NSString *userInsightsLocationTypeStr = (NSString *)userInsightsLocationTypeObj;
        
        if ([userInsightsLocationTypeStr isEqualToString:@"home"]) {
            userInsightsLocationType = RadarUserInsightsLocationTypeHome;
        } else if ([userInsightsLocationTypeStr isEqualToString:@"office"]) {
            userInsightsLocationType = RadarUserInsightsLocationTypeOffice;
        }
    }
    
    id userInsightsLocationLocationObj = userInsightsLocationDict[@"location"];
    if (userInsightsLocationLocationObj && [userInsightsLocationLocationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *userInsightsLocationLocationDict = (NSDictionary *)userInsightsLocationLocationObj;
        
        id userInsightsLocationLocationCoordinatesObj = userInsightsLocationLocationDict[@"coordinates"];
        if (!userInsightsLocationLocationCoordinatesObj || ![userInsightsLocationLocationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }
        
        NSArray *userInsightsLocationLocationCoordinatesArr = (NSArray *)userInsightsLocationLocationCoordinatesObj;
        if (userInsightsLocationLocationCoordinatesArr.count != 2) {
            return nil;
        }
        
        id userInsightsLocationLocationCoordinatesLongitudeObj = userInsightsLocationLocationCoordinatesArr[0];
        id userInsightsLocationLocationCoordinatesLatitudeObj = userInsightsLocationLocationCoordinatesArr[1];
        if (!userInsightsLocationLocationCoordinatesLongitudeObj || !userInsightsLocationLocationCoordinatesLatitudeObj || ![userInsightsLocationLocationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] || ![userInsightsLocationLocationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }
        
        NSNumber *userInsightsLocationLocationCoordinatesLongitudeNumber = (NSNumber *)userInsightsLocationLocationCoordinatesLongitudeObj;
        NSNumber *userInsightsLocationLocationCoordinatesLatitudeNumber = (NSNumber *)userInsightsLocationLocationCoordinatesLatitudeObj;
        
        float userInsightsLocationLocationCoordinatesLongitudeFloat = [userInsightsLocationLocationCoordinatesLongitudeNumber floatValue];
        float userInsightsLocationLocationCoordinatesLatitudeFloat = [userInsightsLocationLocationCoordinatesLatitudeNumber floatValue];
        
        userInsightsLocationLocation = [[CLLocation alloc] initWithLatitude:userInsightsLocationLocationCoordinatesLatitudeFloat longitude:userInsightsLocationLocationCoordinatesLongitudeFloat];
    }
    
    id userInsightsLocationConfidenceObj = userInsightsLocationDict[@"confidence"];
    if (userInsightsLocationConfidenceObj && [userInsightsLocationConfidenceObj isKindOfClass:[NSNumber class]]) {
        NSNumber *userInsightsLocationConfidenceNumber = (NSNumber *)userInsightsLocationConfidenceObj;
        int userInsightsLocationConfidenceInt = [userInsightsLocationConfidenceNumber intValue];
        
        if (userInsightsLocationConfidenceInt == 3) {
            userInsightsLocationConfidence = RadarUserInsightsLocationConfidenceHigh;
        } else if (userInsightsLocationConfidenceInt == 2) {
            userInsightsLocationConfidence = RadarUserInsightsLocationConfidenceMedium;
        } else if (userInsightsLocationConfidenceInt == 1) {
            userInsightsLocationConfidence = RadarUserInsightsLocationConfidenceLow;
        }
    }
    
    id userInsightsLocationUpdatedAtObj = userInsightsLocationDict[@"updatedAt"];
    if (userInsightsLocationUpdatedAtObj && [userInsightsLocationUpdatedAtObj isKindOfClass:[NSString class]]) {
        NSString *userInsightsLocationUpdatedAtStr = (NSString *)userInsightsLocationUpdatedAtObj;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        
        userInsightsLocationUpdatedAt = [dateFormatter dateFromString:userInsightsLocationUpdatedAtStr];
    }
    
    id countryObj = userInsightsLocationDict[@"country"];
    country = [[RadarRegion alloc] initWithObject:countryObj];
    
    id stateObj = userInsightsLocationDict[@"state"];
    state = [[RadarRegion alloc] initWithObject:stateObj];
    
    id dmaObj = userInsightsLocationDict[@"dma"];
    dma = [[RadarRegion alloc] initWithObject:dmaObj];
    
    id postalCodeObj = userInsightsLocationDict[@"postalCode"];
    postalCode = [[RadarRegion alloc] initWithObject:postalCodeObj];
    
    if (userInsightsLocationLocation && userInsightsLocationUpdatedAt) {
        return [[RadarUserInsightsLocation alloc] initWithType:userInsightsLocationType location:userInsightsLocationLocation confidence:userInsightsLocationConfidence updatedAt:userInsightsLocationUpdatedAt country:country state:state dma:dma postalCode:postalCode];
    }
    
    return nil;
}

@end
