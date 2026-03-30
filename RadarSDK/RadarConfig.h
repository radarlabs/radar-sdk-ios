//
//  RadarConfig.h
//  RadarSDK
//
//  Created by Nick Patrick on 1/4/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarMeta.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarConfig : NSObject

@property (nullable, strong, nonatomic) RadarMeta *meta;
@property (nullable, copy, nonatomic) NSString *nonce;

+ (RadarConfig *_Nullable)fromDictionary:(NSDictionary *_Nullable)dict;

@end

NS_ASSUME_NONNULL_END
