//
//  RadarRegion+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarRegion.h"

@interface RadarRegion ()<RadarJSONCoding>

- (nonnull instancetype)initWithId:(nonnull NSString *)_id name:(nonnull NSString *)name code:(nonnull NSString *)code type:(nonnull NSString *)type flag:(nullable NSString *)flag;

@end
