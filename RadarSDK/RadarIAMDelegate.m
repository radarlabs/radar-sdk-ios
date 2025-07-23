//
//  RadarIAMDelegate.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/23/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarSDK/RadarSDK-Swift.h"
#import "UIKit/UIkit.h"
#import "RadarIAMDelegate.h"

@implementation RadarIAMDelegate

API_AVAILABLE(ios(13.0))
RadarIAMDelegate* radarIAMDelegate = nil;

- (instancetype) init {
    if (radarIAMDelegate == nil) {
        radarIAMDelegate = [RadarIAMDelegate_Swift alloc];
        radarIAMDelegate = [radarIAMDelegate init];
        NSLog(@"iam Initialized IAM Delegate");
    }
    return self;
}

- (void)getIAMViewController:(RadarInAppMessage * _Nonnull)message completionHandler:(nonnull void (^)(UIViewController * _Nonnull __strong))completionHandler {
    NSLog(@"iam GETTING CONTROLLER");
    [radarIAMDelegate getIAMViewController:message completionHandler:completionHandler];
}

- (void)onIAMPositiveAction:(RadarInAppMessage * _Nonnull)message {
    [radarIAMDelegate onIAMPositiveAction:message];
}

@end
