//
//  RadarRegion+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarRegion.h"

@interface RadarRegion ()

- (nonnull instancetype)initWithId:(nonnull NSString *)_id
                              name:(nonnull NSString *)name
                              code:(nonnull NSString *)code
                              type:(nonnull NSString *)type
                              flag:(nullable NSString *)flag
                           allowed:(BOOL)allowed
                            passed:(BOOL)passed
                   inExclusionZone:(BOOL)inExclusionZone
                      inBufferZone:(BOOL)inBufferZone
                  distanceToBorder:(double)distanceToBorder
                          expected:(BOOL)expected;
- (nullable instancetype)initWithObject:(nullable id)object;

@end
