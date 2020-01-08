//
//  RadarAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarAddress.h"
#import "RadarCoordinate.h"

@interface RadarAddress ()

+ (NSArray<RadarAddress *> * _Nullable)addressesFromObject:(id _Nonnull)object;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

- (instancetype _Nullable)initWithCoordinate:(CLLocationCoordinate2D)coordinate
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
                                  confidence:(RadarAddressConfidence)confidence;

@end
