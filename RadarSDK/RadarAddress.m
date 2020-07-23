//
//  RadarAddress.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAddress+Internal.h"
#import "RadarCoordinate+Internal.h"

@implementation RadarAddress

+ (NSArray<RadarAddress *> *_Nullable)addressesFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *addressesArr = (NSArray *)object;
    NSMutableArray<RadarAddress *> *mutableAddresses = [NSMutableArray<RadarAddress *> new];

    for (id addressObj in addressesArr) {
        RadarAddress *address = [[RadarAddress alloc] initWithObject:addressObj];
        if (!address) {
            return nil;
        }
        [mutableAddresses addObject:address];
    }

    return mutableAddresses;
}

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

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSNumber *latitude;
    NSNumber *longitude;
    CLLocationCoordinate2D coordinate;

    NSString *formattedAddress;
    NSString *country;
    NSString *countryCode;
    NSString *countryFlag;
    NSString *dma;
    NSString *dmaCode;
    NSString *state;
    NSString *stateCode;
    NSString *postalCode;
    NSString *city;
    NSString *borough;
    NSString *county;
    NSString *neighborhood;
    NSString *number;
    NSString *addressLabel;
    NSString *placeLabel;

    RadarAddressConfidence confidence = RadarAddressConfidenceNone;

    id latitudeObj = dict[@"latitude"];
    if (latitudeObj && [latitudeObj isKindOfClass:[NSNumber class]]) {
        latitude = (NSNumber *)latitudeObj;
    }

    id longitudeObj = dict[@"longitude"];
    if (longitudeObj && [longitudeObj isKindOfClass:[NSNumber class]]) {
        longitude = (NSNumber *)longitudeObj;
    }

    if (latitude && longitude) {
        coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
    } else {
        coordinate = kCLLocationCoordinate2DInvalid;
    }

    id formattedAddressObj = dict[@"formattedAddress"];
    if (formattedAddressObj && [formattedAddressObj isKindOfClass:[NSString class]]) {
        formattedAddress = (NSString *)formattedAddressObj;
    }

    id countryObj = dict[@"country"];
    if (countryObj && [countryObj isKindOfClass:[NSString class]]) {
        country = (NSString *)countryObj;
    }

    id countryCodeObj = dict[@"countryCode"];
    if (countryCodeObj && [countryCodeObj isKindOfClass:[NSString class]]) {
        countryCode = (NSString *)countryCodeObj;
    }

    id countryFlagObj = dict[@"countryFlag"];
    if (countryFlagObj && [countryFlagObj isKindOfClass:[NSString class]]) {
        countryFlag = (NSString *)countryFlagObj;
    }

    id dmaObj = dict[@"dma"];
    if (dmaObj && [dmaObj isKindOfClass:[NSString class]]) {
        dma = (NSString *)dmaObj;
    }

    id dmaCodeObj = dict[@"dmaCode"];
    if (dmaCodeObj && [dmaCodeObj isKindOfClass:[NSString class]]) {
        dmaCode = (NSString *)dmaCodeObj;
    }

    id stateObj = dict[@"state"];
    if (stateObj && [stateObj isKindOfClass:[NSString class]]) {
        state = (NSString *)stateObj;
    }

    id stateCodeObj = dict[@"stateCode"];
    if (stateCodeObj && [stateCodeObj isKindOfClass:[NSString class]]) {
        stateCode = (NSString *)stateCodeObj;
    }

    id postalCodeObj = dict[@"postalCode"];
    if (postalCodeObj && [postalCodeObj isKindOfClass:[NSString class]]) {
        postalCode = (NSString *)postalCodeObj;
    }

    id cityObj = dict[@"city"];
    if (cityObj && [cityObj isKindOfClass:[NSString class]]) {
        city = (NSString *)cityObj;
    }

    id boroughObj = dict[@"borough"];
    if (boroughObj && [boroughObj isKindOfClass:[NSString class]]) {
        borough = (NSString *)boroughObj;
    }

    id countyObj = dict[@"county"];
    if (countyObj && [countyObj isKindOfClass:[NSString class]]) {
        county = (NSString *)countyObj;
    }

    id neighborhoodObj = dict[@"neighborhood"];
    if (neighborhoodObj && [neighborhoodObj isKindOfClass:[NSString class]]) {
        neighborhood = (NSString *)neighborhoodObj;
    }

    id addressNumberObj = dict[@"number"];
    if (addressNumberObj && [addressNumberObj isKindOfClass:[NSString class]]) {
        number = (NSString *)addressNumberObj;
    }

    id addressLabelObj = dict[@"addressLabel"];
    if (addressLabelObj && [addressLabelObj isKindOfClass:[NSString class]]) {
        addressLabel = (NSString *)addressLabelObj;
    }

    id placeLabelObj = dict[@"placeLabel"];
    if (placeLabelObj && [placeLabelObj isKindOfClass:[NSString class]]) {
        placeLabel = (NSString *)placeLabelObj;
    }

    id confidenceObj = dict[@"confidence"];
    if (confidenceObj && [confidenceObj isKindOfClass:[NSString class]]) {
        NSString *confidenceStr = (NSString *)confidenceObj;

        if ([confidenceStr isEqualToString:@"exact"]) {
            confidence = RadarAddressConfidenceExact;
        } else if ([confidenceStr isEqualToString:@"interpolated"]) {
            confidence = RadarAddressConfidenceInterpolated;
        } else if ([confidenceStr isEqualToString:@"fallback"]) {
            confidence = RadarAddressConfidenceFallback;
        }
    }

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

+ (NSArray<NSDictionary *> *)arrayForAddresses:(NSArray<RadarAddress *> *)addresses {
    if (!addresses) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:addresses.count];
    for (RadarAddress *address in addresses) {
        NSDictionary *dict = [address dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
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

@end
