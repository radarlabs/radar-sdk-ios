//
//  RadarRegion+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarSegment.h"

@interface RadarSegment ()

+ (nullable NSArray<RadarSegment *> *)segmentsFromObject:(nullable id)object;

- (nonnull instancetype)initWithDescription:(nonnull NSString *)description externalId:(nonnull NSString *)externalId;

- (nullable instancetype)initWithObject:(nullable id)object;

@end
