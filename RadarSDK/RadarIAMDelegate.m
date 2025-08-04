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
#import "RadarInAppMessageDelegate.h"

@implementation RadarInAppMessageDelegate

API_AVAILABLE(ios(13.0))
RadarInAppMessageDelegate_Swift* radarIAMDelegate = nil;

- (instancetype) init {
    if (radarIAMDelegate == nil) {
        radarIAMDelegate = [[RadarInAppMessageDelegate_Swift alloc] init];
    }
    return self;
}

- (void)createInAppMessageView:(RadarInAppMessage * _Nonnull)message completionHandler:(nonnull void (^)(UIViewController * _Nonnull __strong))completionHandler {
    [radarIAMDelegate createInAppMessageView:message completionHandler:completionHandler];
}

- (void)onInAppMessageButtonClicked:(RadarInAppMessage * _Nonnull)message {
    [radarIAMDelegate onInAppMessageButtonClicked:message];
}

- (void)onInAppMessageDismissed:(RadarInAppMessage * _Nonnull)message {
    [radarIAMDelegate onInAppMessageDismissed:message];
}

- (RadarInAppMessageOperation)onNewInAppMessage:(RadarInAppMessage * _Nonnull)message {
    return [radarIAMDelegate onNewInAppMessage:message];
}

@end
