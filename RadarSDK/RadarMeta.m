//
//  RadarMeta.m
//  RadarSDK
//
//  Created by Jeff Kao on 10/1/21.
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarMeta.h"
#import "RadarTrackingOptions.h"

@implementation RadarMeta

+ (RadarMeta *)fromDictionary:(NSDictionary *)dict {
    RadarMeta *meta = [RadarMeta new];

    if (dict) {
        id trackingOptionsObj = dict[@"trackingOptions"];
        if (trackingOptionsObj && [trackingOptionsObj isKindOfClass:[NSDictionary class]]) {
            meta.trackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:trackingOptionsObj];
        }
    }

    return meta;
}

@end
