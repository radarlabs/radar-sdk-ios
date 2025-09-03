//
//  RadarAddress.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAddress+Internal.h"
#import "RadarCoordinate+Internal.h"
#import "RadarTimeZone+Internal.h"

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

+ (RadarAddress *_Nullable)addressFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    RadarAddress *address = [[RadarAddress alloc] initWithObject:object];
    if (!address) {
        return nil;
    }

    return address;
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
                                      street:(NSString *_Nullable)street
                                addressLabel:(NSString *_Nullable)addressLabel
                                  placeLabel:(NSString *_Nullable)placeLabel
                                        unit:(NSString *_Nullable)unit
                                       plus4:(NSString *_Nullable)plus4
                                    distance:(NSNumber *_Nullable)distance
                                       layer:(NSString *_Nullable)layer
                                    metadata:(NSDictionary *_Nullable)metadata
                                  confidence:(RadarAddressConfidence)confidence
                                    timeZone:(RadarTimeZone *_Nullable)timeZone
                                  categories:(NSArray<NSString *> *_Nullable)categories {
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
        _street = street;
        _addressLabel = addressLabel;
        _placeLabel = placeLabel;
        _unit = unit;
        _plus4 = plus4;
        _distance = distance;
        _layer = layer;
        _metadata = metadata;
        _confidence = confidence;
        _timeZone = timeZone;
        _categories = categories;
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
    NSString *street;
    NSString *addressLabel;
    NSString *placeLabel;
    NSString *unit;
    NSString *plus4;
    NSNumber *distance;
    NSString *layer;
    NSMutableDictionary *metadata;

    RadarAddressConfidence confidence = RadarAddressConfidenceNone;
    RadarTimeZone *timeZone;
    NSArray<NSString *> *categories;

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

    id streetObj = dict[@"street"];
    if (streetObj && [streetObj isKindOfClass:[NSString class]]) {
        street = (NSString *)streetObj;
    }

    id addressLabelObj = dict[@"addressLabel"];
    if (addressLabelObj && [addressLabelObj isKindOfClass:[NSString class]]) {
        addressLabel = (NSString *)addressLabelObj;
    }

    id placeLabelObj = dict[@"placeLabel"];
    if (placeLabelObj && [placeLabelObj isKindOfClass:[NSString class]]) {
        placeLabel = (NSString *)placeLabelObj;
    }

    id unitObj = dict[@"unit"];
    if (unitObj && [unitObj isKindOfClass:[NSString class]]) {
        unit = (NSString *)unitObj;
    }

    id plus4Obj = dict[@"plus4"];
    if (plus4Obj && [plus4Obj isKindOfClass:[NSString class]]) {
        plus4 = (NSString *)plus4Obj;
    }

    id distanceObj = dict[@"distance"];
    if (distanceObj && [distanceObj isKindOfClass:[NSNumber class]]) {
        distance = (NSNumber *)distanceObj;
    }

    id layerObj = dict[@"layer"];
    if (layerObj && [layerObj isKindOfClass:[NSString class]]) {
        layer = (NSString *)layerObj;
    }

    id metadataObj = dict[@"metadata"];
    if (metadataObj && [metadataObj isKindOfClass:[NSDictionary class]]) {
        metadata = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)metadataObj];
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
    
    id timeZoneObj = dict[@"timeZone"];
    if (timeZoneObj && [timeZoneObj isKindOfClass:[NSDictionary class]]) {
        timeZone = [[RadarTimeZone alloc] initWithObject:timeZoneObj];
    }

    id categoriesObj = dict[@"categories"];
    if (categoriesObj && [categoriesObj isKindOfClass:[NSArray class]]) {
        NSMutableArray<NSString *> *validCategories = [NSMutableArray array];
        for (id category in (NSArray *)categoriesObj) {
            if ([category isKindOfClass:[NSString class]]) {
                [validCategories addObject:(NSString *)category];
            }
        }
        categories = [validCategories copy];
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
                                             street:street
                                       addressLabel:addressLabel
                                         placeLabel:placeLabel
                                               unit:unit
                                              plus4:plus4
                                           distance:distance
                                              layer:layer
                                           metadata:metadata
                                         confidence:confidence
                                           timeZone:timeZone
                                         categories:categories];
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

+ (RadarAddressVerificationStatus)addressVerificationStatusForString:(NSString *)string {
    if ([string isEqualToString:@"verified"]) {
        return RadarAddressVerificationStatusVerified;
    } else if ([string isEqualToString:@"partially verified"]) {
        return RadarAddressVerificationStatusPartiallyVerified;
    } else if ([string isEqualToString:@"ambiguous"]) {
        return RadarAddressVerificationStatusAmbiguous;
    } else if ([string isEqualToString:@"unverified"]) {
        return RadarAddressVerificationStatusUnverified;
    } else {
        return RadarAddressVerificationStatusNone;
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
    [dict setValue:self.street forKey:@"street"];
    [dict setValue:self.addressLabel forKey:@"addressLabel"];
    [dict setValue:self.placeLabel forKey:@"placeLabel"];
    [dict setValue:self.unit forKey:@"unit"];
    [dict setValue:self.plus4 forKey:@"plus4"];
    [dict setValue:self.distance forKey:@"distance"];
    [dict setValue:self.layer forKey:@"layer"];
    [dict setValue:self.metadata forKey:@"metadata"];
    [dict setValue:[RadarAddress stringForConfidence:self.confidence] forKey:@"confidence"];
    [dict setValue:[self.timeZone dictionaryValue] forKey:@"timeZone"];
    [dict setValue:self.categories forKey:@"categories"];
    return dict;
}

@end
