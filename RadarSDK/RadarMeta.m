//
//  RadarMeta.m
//  RadarSDK
//
//  Created by Jeff Kao on 10/1/21.
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarMeta.h"

@implementation RadarMeta

+ (RadarMeta *)fromDictionary:(NSDictionary *)dict {
    RadarMeta *meta = [RadarMeta new];

    if (dict) {
        id trackingOptionsObj = dict[@"trackingOptions"];
        if (trackingOptionsObj && [trackingOptionsObj isKindOfClass:[NSDictionary class]]) {
            meta.trackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:trackingOptionsObj];
        }
        id featureSettingsObj = dict[@"featureSettings"];
        if (featureSettingsObj && [featureSettingsObj isKindOfClass:[NSDictionary class]]) {
            meta.featureSettings = [RadarFeatureSettings featureSettingsFromDictionary:featureSettingsObj];
        }
        id sdkConfigurationObj = dict[@"sdkConfiguration"];
        if (sdkConfigurationObj && [sdkConfigurationObj isKindOfClass:[NSDictionary class]]) {
<<<<<<< HEAD
            meta.sdkConfiguration = [RadarSDKConfiguration sdkConfigurationFromDictionary:sdkConfigurationObj];
=======
            meta.sdkConfiguration = [RadarSdkConfiguration sdkConfigurationFromDictionary:sdkConfigurationObj];
>>>>>>> shicheng/fence-1948-set-log-level-in-sdk-in-initialize
        }
    }

    return meta;
}

@end
