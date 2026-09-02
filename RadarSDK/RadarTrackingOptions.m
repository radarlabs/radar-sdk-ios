//
//  RadarTrackingOptions.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrackingOptions.h"

@interface RadarTrackingOptions (SwiftFactory)

+ (RadarTrackingOptions *_Nullable)radar_trackingOptionsFromDictionary:(NSDictionary *_Nullable)dictionary;

@end

@implementation RadarTrackingOptions (Dictionary)

+ (RadarTrackingOptions *)trackingOptionsFromDictionary:(NSDictionary *)dictionary {
    return [self radar_trackingOptionsFromDictionary:dictionary];
}

@end
