//
//  RadarRegion+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarSegment.h"

@interface RadarSegment ()<RadarJSONCoding>

+ (nullable NSArray<RadarSegment *> *)segmentsFromObject:(nullable id)object;

- (nonnull instancetype)initWithDescription:(nonnull NSString *)description externalId:(nonnull NSString *)externalId;

@end
