//
//  RadarInAppMessage.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/18/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarInAppMessage.h"
#import "Radar-Swift.h"

@implementation RadarInAppMessage

+ (RadarInAppMessage * _Nullable)fromDictionary:(NSDictionary<NSString *, id> * _Nonnull)dict {
    return [RadarInAppMessage_Swift fromDictionary:dict];
}

+ (NSArray<RadarInAppMessage *> * _Nonnull)fromArray:(id _Nonnull)array {
    return [RadarInAppMessage_Swift fromArray:array];
}

- (NSDictionary<NSString *, id> * _Nonnull)toDictionary {
    return [RadarInAppMessage_Swift toDictionary:self];
}

@end
