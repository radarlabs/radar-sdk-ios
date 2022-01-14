//
//  RadarAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAddress.h"
#import "RadarCoordinate.h"
#import <Foundation/Foundation.h>

@interface RadarAddress ()

+ (NSArray<RadarAddress *> *_Nullable)addressesFromObject:(id _Nonnull)object;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

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
                                  confidence:(RadarAddressConfidence)confidence;

@end
