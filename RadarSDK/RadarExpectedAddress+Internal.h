//
//  RadarExpectedAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarExpectedAddress.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarExpectedAddress ()

- (instancetype _Nonnull)initWithExpectedAddress:(NSString *_Nonnull)expectedAddress
                                formattedAddress:(NSString *_Nullable)formattedAddress
                                        latitude:(NSNumber *_Nullable)latitude
                                       longitude:(NSNumber *_Nullable)longitude
                                       atAddress:(BOOL)atAddress
                                      confidence:(RadarExpectedAddressConfidence)confidence
                                        distance:(NSNumber *_Nullable)distance;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end

NS_ASSUME_NONNULL_END
