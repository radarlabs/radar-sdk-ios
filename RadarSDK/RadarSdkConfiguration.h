//
//  RadarSdkConfiguration.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radar.h"
@class RadarRemoteTrackingOptions;

NS_ASSUME_NONNULL_BEGIN

/**
 Represents server-side sdk configuration.
 
 @see https://radar.com/documentation/sdk/ios
 */
@interface RadarSdkConfiguration_ObjC : NSObject

+ (void)updateSdkConfigurationFromServer;

@end

NS_ASSUME_NONNULL_END
