//
//  RadarTrackingOptions.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrackingOptions.h"

// Swift's @objc @implementation cannot implement Objective-C factory
// convenience initializers. Keep this category as a compatibility shim so
// +trackingOptionsFromDictionary: remains available to Objective-C callers
// and continues importing into Swift as init(from:).

@interface RadarTrackingOptions (SwiftFactory)

+ (RadarTrackingOptions *_Nullable)radar_trackingOptionsFromDictionary:(NSDictionary *_Nullable)dictionary;

@end

@implementation RadarTrackingOptions (Dictionary)

+ (RadarTrackingOptions *)trackingOptionsFromDictionary:(NSDictionary *)dictionary {
    return [self radar_trackingOptionsFromDictionary:dictionary];
}

@end
