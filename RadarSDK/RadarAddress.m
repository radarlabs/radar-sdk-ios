//
//  RadarAddress.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAddress+Internal.h"
#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"
#import "RadarJSONCoding.h"

@implementation RadarAddress

- (instancetype _Nullable)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                            formattedAddress:(NSString *_Nullable)formattedAddress
                                     country:(NSString *_Nullable)country
                                 countryCode:(NSString *_Nullable)countryCode
                                 countryFlag:(NSString *_Nullable)countryFlag
                                         dma:(NSString *_Nullable)dma
                                     dmaCode:(NSString *_Nullable)dmaCode
                                       state:(NSString *_Nullable)state
                                   stateCode:(NSString *_Nullable)stateCode
                                  postalCode:(NSString *_Nullable)postalCode
                                        city:(NSString *_Nullable)city
                                     borough:(NSString *_Nullable)borough
                                      county:(NSString *_Nullable)county
                                neighborhood:(NSString *_Nullable)neighborhood
                                      number:(NSString *_Nullable)number
                                addressLabel:(NSString *_Nullable)addressLabel
                                  placeLabel:(NSString *_Nullable)placeLabel
                                  confidence:(RadarAddressConfidence)confidence {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _formattedAddress = formattedAddress;
        _country = country;
        _countryCode = countryCode;
        _countryFlag = countryFlag;
        _dma = dma;
        _dmaCode = dmaCode;
        _state = state;
        _stateCode = stateCode;
        _postalCode = postalCode;
        _city = city;
        _borough = borough;
        _county = county;
        _neighborhood = neighborhood;
        _number = number;
        _addressLabel = addressLabel;
        _placeLabel = placeLabel;
        _confidence = confidence;
    }
    return self;
}

#pragma mark - JSON coding
+ (NSArray<RadarAddress *> *_Nullable)addressesFromObject:(id _Nonnull)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarAddress);
}

- (instancetype _Nullable)initWithObject:(id _Nullable)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSNumber *latitude = [dict radar_numberForKey:@"latitude"];
    NSNumber *longitude = [dict radar_numberForKey:@"longitude"];

    CLLocationCoordinate2D coordinate;
    if (latitude && longitude) {
        coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
    } else {
        coordinate = kCLLocationCoordinate2DInvalid;
    }

    NSString *formattedAddress = [dict radar_stringForKey:@"formattedAddress"];
    NSString *country = [dict radar_stringForKey:@"country"];
    NSString *countryCode = [dict radar_stringForKey:@"countryCode"];
    NSString *countryFlag = [dict radar_stringForKey:@"countryFlag"];
    NSString *dma = [dict radar_stringForKey:@"dma"];
    NSString *dmaCode = [dict radar_stringForKey:@"dmaCode"];
    NSString *state = [dict radar_stringForKey:@"state"];
    NSString *stateCode = [dict radar_stringForKey:@"stateCode"];
    NSString *postalCode = [dict radar_stringForKey:@"postalCode"];
    NSString *city = [dict radar_stringForKey:@"city"];
    NSString *borough = [dict radar_stringForKey:@"borough"];
    NSString *county = [dict radar_stringForKey:@"county"];
    NSString *neighborhood = [dict radar_stringForKey:@"neighborhood"];
    NSString *number = [dict radar_stringForKey:@"number"];
    NSString *addressLabel = [dict radar_stringForKey:@"addressLabel"];
    NSString *placeLabel = [dict radar_stringForKey:@"placeLabel"];

    NSString *confidenceStr = [dict radar_stringForKey:@"confidence"];
    RadarAddressConfidence confidence = [RadarAddress confidenceFromString:confidenceStr];

    return [[RadarAddress alloc] initWithCoordinate:coordinate
                                   formattedAddress:formattedAddress
                                            country:country
                                        countryCode:countryCode
                                        countryFlag:countryFlag
                                                dma:dma
                                            dmaCode:dmaCode
                                              state:state
                                          stateCode:stateCode
                                         postalCode:postalCode
                                               city:city
                                            borough:borough
                                             county:county
                                       neighborhood:neighborhood
                                             number:number
                                       addressLabel:addressLabel
                                         placeLabel:placeLabel
                                         confidence:confidence];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.coordinate.latitude) forKey:@"latitude"];
    [dict setValue:@(self.coordinate.longitude) forKey:@"longitude"];
    [dict setValue:self.formattedAddress forKey:@"formattedAddress"];
    [dict setValue:self.country forKey:@"country"];
    [dict setValue:self.countryCode forKey:@"countryCode"];
    [dict setValue:self.countryFlag forKey:@"countryFlag"];
    [dict setValue:self.dma forKey:@"dma"];
    [dict setValue:self.dmaCode forKey:@"dmaCode"];
    [dict setValue:self.state forKey:@"state"];
    [dict setValue:self.stateCode forKey:@"stateCode"];
    [dict setValue:self.postalCode forKey:@"postalCode"];
    [dict setValue:self.city forKey:@"city"];
    [dict setValue:self.borough forKey:@"borough"];
    [dict setValue:self.county forKey:@"county"];
    [dict setValue:self.neighborhood forKey:@"neighborhood"];
    [dict setValue:self.number forKey:@"number"];
    [dict setValue:self.addressLabel forKey:@"addressLabel"];
    [dict setValue:self.placeLabel forKey:@"placeLabel"];
    [dict setValue:[RadarAddress stringForConfidence:self.confidence] forKey:@"confidence"];
    return dict;
}

+ (NSArray<NSDictionary *> *)arrayForAddresses:(NSArray<RadarAddress *> *)addresses {
    TO_JSON_ARRAY_DEFAULT_IMP(addresses, RadarAddress);
}

+ (NSString *)stringForConfidence:(RadarAddressConfidence)confidence {
    switch (confidence) {
    case RadarAddressConfidenceExact:
        return @"exact";
    case RadarAddressConfidenceInterpolated:
        return @"interpolated";
    case RadarAddressConfidenceFallback:
        return @"fallback";
    default:
        return @"none";
    }
}

+ (RadarAddressConfidence)confidenceFromString:(NSString *)confidenceStr {
    if ([confidenceStr isEqualToString:@"exact"]) {
        return RadarAddressConfidenceExact;
    } else if ([confidenceStr isEqualToString:@"interpolated"]) {
        return RadarAddressConfidenceInterpolated;
    } else if ([confidenceStr isEqualToString:@"fallback"]) {
        return RadarAddressConfidenceFallback;
    } else {
        return RadarAddressConfidenceNone;
    }
}

@end
