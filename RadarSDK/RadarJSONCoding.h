//
//  RadarJSONCoding.h
//  Library
//
//  Created by Ping Xia on 4/22/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RadarJSONCoding

- (nullable instancetype)initWithRadarJSONObject:(nullable id)object;

- (id)toRadarJSONObject; // RadarJSONObject is either a NSDictionary or a NSArray

@end

NS_ASSUME_NONNULL_END
