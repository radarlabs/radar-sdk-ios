//
//  RadarSdkConfiguration.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarSdkConfiguration.h"
//#include "Radar.h"
//
//#import "RadarLog.h"
//#import "RadarUtils.h"
#import "RadarAPIClient.h"
#import "RadarSettings.h"
//
//@interface RadarSdkConfiguration ()
//
//@property (nonatomic, strong) NSDictionary *originalDict;
//
//@end
//
@implementation RadarSdkConfiguration_ObjC

+ (void)updateSdkConfigurationFromServer {
    [[RadarAPIClient sharedInstance] getConfigForUsage:@"sdkConfigUpdate" 
                                              verified:false
                                     completionHandler:^(RadarStatus status, RadarConfig *config) {
                                         if (status != RadarStatusSuccess || !config) {
                                            return;
                                         }
                                         [RadarSettings setSdkConfiguration:config.meta.sdkConfiguration];
                                     }];
}

@end
