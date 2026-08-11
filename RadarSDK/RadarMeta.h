//
//  RadarMeta.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarSdkConfiguration.h"
#import "RadarTrackingOptions.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarMeta : NSObject

@property (nullable, strong, nonatomic, readwrite) RadarTrackingOptions *trackingOptions;
@property (nullable, strong, nonatomic, readwrite) RadarSdkConfiguration *sdkConfiguration;

+ (RadarMeta *_Nullable)fromDictionary:(NSDictionary *_Nullable)dict;

@end

NS_ASSUME_NONNULL_END
