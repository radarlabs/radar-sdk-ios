//
//  RadarAddress.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAddress+Internal.h"
#import "RadarCoordinate+Internal.h"

@implementation RadarAddress

+ (NSArray<RadarAddress *> * _Nullable)addressesFromObject:(id _Nonnull)object {
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

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *addressDict = (NSDictionary *)object;

    RadarCoordinate *coordinate;
    NSString *formattedAddress;
    NSString *country;
    NSString *countryCode;
    NSString *countryFlag;
    NSString *state;
    NSString *stateCode;
    NSString *postalCode;
    NSString *city;
    NSString *borough;
    NSString *county;
    NSString *neighborhood;
    NSString *number;
    RadarAddressConfidence *confidence;

    // TODO (jsani): verify serializing RadarCoordinate correctly
    id coordinateObj = addressDict[@"coordinate"];
    if (coordinateObj && [coordinateObj isKindOfClass:[RadarCoordinate class]]) {
        coordinate = (RadarCoordinate *)coordinateObj;
    }

    id formattedAddressObj = addressDict[@"formattedAddress"];
    if (formattedAddressObj && [formattedAddressObj isKindOfClass:[NSString class]]) {
        formattedAddress = (NSString *)formattedAddressObj;
    }

    id countryObj = addressDict[@"country"];
    if (countryObj && [countryObj isKindOfClass:[NSString class]]) {
        country = (NSString *)countryObj;
    }

    id countryCodeObj = addressDict[@"countryCode"];
    if (countryCodeObj && [countryCodeObj isKindOfClass:[NSString class]]) {
        countryCode = (NSString *)countryCodeObj;
    }

    id countryFlagObj = addressDict[@"countryFlag"];
    if (countryFlagObj && [countryFlagObj isKindOfClass:[NSString class]]) {
        countryFlag = (NSString *)countryFlagObj;
    }

    id stateObj = addressDict[@"state"];
    if (stateObj && [stateObj isKindOfClass:[NSString class]]) {
        state = (NSString *)stateObj;
    }

    id stateCodeObj = addressDict[@"stateCode"];
    if (stateCodeObj && [stateCodeObj isKindOfClass:[NSString class]]) {
        stateCode = (NSString *)stateCodeObj;
    }

    id postalCodeObj = addressDict[@"postalCode"];
    if (postalCodeObj && [postalCodeObj isKindOfClass:[NSString class]]) {
        postalCode = (NSString *)postalCodeObj;
    }

    id cityObj = addressDict[@"city"];
    if (cityObj && [cityObj isKindOfClass:[NSString class]]) {
        city = (NSString *)cityObj;
    }

    id boroughObj = addressDict[@"borough"];
    if (boroughObj && [boroughObj isKindOfClass:[NSString class]]) {
        borough = (NSString *)boroughObj;
    }

    id countyObj = addressDict[@"county"];
    if (countyObj && [countyObj isKindOfClass:[NSString class]]) {
        county = (NSString *)countyObj;
    }

    id neighborhoodObj = addressDict[@"neighborhood"];
    if (neighborhoodObj && [neighborhoodObj isKindOfClass:[NSString class]]) {
        neighborhood = (NSString *)neighborhoodObj;
    }

    id addressNumberObj = addressDict[@"number"];
    if (addressNumberObj && [addressNumberObj isKindOfClass:[NSString class]]) {
        number = (NSString *)addressNumberObj;
    }

    // TODO (jsani): how to serialize RadarAddressConfidence?

    if (coordinate && confidence) {
        return [[RadarAddress alloc] initWithCoordinate:coordinate formattedAddress:formattedAddress country:country countryCode:countryCode countryFlag:countryFlag state:state stateCode:stateCode postalCode:postalCode city:city borough:borough county:county neighborhood:neighborhood number:number confidence:confidence];
    }

    return nil;
}

- (instancetype _Nullable)initWithCoordinate:(RadarCoordinate * _Nonnull)coordinate
                            formattedAddress:(NSString * _Nullable)formattedAddress
                                     country:(NSString * _Nullable)country
                                 countryCode:(NSString * _Nullable)countryCode
                                 countryFlag:(NSString * _Nullable)countryFlag
                                       state:(NSString * _Nullable)state
                                   stateCode:(NSString * _Nullable)stateCode
                                  postalCode:(NSString * _Nullable)postalCode
                                        city:(NSString * _Nullable)city
                                     borough:(NSString * _Nullable)borough
                                      county:(NSString * _Nullable)county
                                neighborhood:(NSString * _Nullable)neighborhood
                                      number:(NSString * _Nullable)number
                                  confidence:(RadarAddressConfidence * _Nonnull)confidence {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _formattedAddress = formattedAddress;
        _country = country;
        _countryCode = countryCode;
        _countryFlag = countryFlag;
        _state = state;
        _stateCode = stateCode;
        _postalCode = postalCode;
        _city = city;
        _borough = borough;
        _county = county;
        _neighborhood = neighborhood;
        _number = number;

        // TODO (jsani): Xcode complains about _confidence on LHS?
        confidence = confidence;
    }
    return self;
}

@end
