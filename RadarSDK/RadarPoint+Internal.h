//
//  RadarPoint+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarPoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarPoint ()<RadarJSONCoding>

+ (NSArray<RadarPoint *> *_Nullable)pointsFromObject:(id)object;
- (instancetype _Nullable)initWithId:(NSString *)_id
                         description:(NSString *)description
                                 tag:(NSString *_Nullable)tag
                          externalId:(NSString *_Nullable)externalId
                            metadata:(NSDictionary *_Nullable)metadata
                            location:(RadarCoordinate *)location;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
