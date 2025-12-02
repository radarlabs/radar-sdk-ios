//
//  RadarConfig.m
//  RadarSDK
//
//  Created by Nick Patrick on 1/4/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarConfig.h"
#import "RadarMeta.h"
#import <Foundation/Foundation.h>

@implementation RadarConfig

+ (RadarConfig *)fromDictionary:(NSDictionary *)dict {
    RadarConfig *config = [RadarConfig new];

    if (dict) {
        id metaObj = dict[@"meta"];
        if (metaObj && [metaObj isKindOfClass:[NSDictionary class]]) {
            config.meta = [RadarMeta fromDictionary:metaObj];
        }

        id challengeObj = dict[@"nonce"];
        if (challengeObj && [challengeObj isKindOfClass:[NSString class]]) {
            config.challenge = (NSString *)challengeObj;
        }
    }

    return config;
}

@end
