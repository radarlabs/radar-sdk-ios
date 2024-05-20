//
//  RadarMeta.h
//  RadarSDK
//
//  Created by Jeff Kao on 10/1/21.
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrackingOptions.h"
#import "RadarFeatureSettings.h"
#import "RadarSdkConfiguration.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarMeta : NSObject

@property (nullable, strong, nonatomic, readwrite) RadarTrackingOptions *trackingOptions;
@property (nullable, strong, nonatomic, readwrite) RadarFeatureSettings *featureSettings;
@property (nullable, strong, nonatomic, readwrite) RadarSdkConfiguration *sdkConfiguration;

+ (RadarMeta *_Nullable)fromDictionary:(NSDictionary *_Nullable)dict;

@end

NS_ASSUME_NONNULL_END
