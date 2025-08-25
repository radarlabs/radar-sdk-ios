//
//  RadarIAMDelegate.m
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarInAppMessageDelegate.h"
#import "Radar-Swift.h"

@implementation RadarInAppMessageDelegate

API_AVAILABLE(ios(13.0))
RadarInAppMessageDelegate_Swift* radarIAMDelegate = nil;

- (instancetype) init {
    if (radarIAMDelegate == nil) {
        radarIAMDelegate = [[RadarInAppMessageDelegate_Swift alloc] init];
    }
    return self;
}

- (void)createInAppMessageView:(RadarInAppMessage * _Nonnull)message
                     onDismiss:(void (^)(void))onDismiss
         onInAppMessageClicked:(void (^)(void))onInAppMessageClicked
             completionHandler:(nonnull void (^)(UIViewController * _Nonnull __strong))completionHandler {
    [radarIAMDelegate createInAppMessageView:message onDismiss:onDismiss onInAppMessageClicked:onInAppMessageClicked completionHandler:completionHandler];
}

- (void)onInAppMessageButtonClicked:(RadarInAppMessage * _Nonnull)message {
    [radarIAMDelegate onInAppMessageButtonClicked:message];
}

- (void)onInAppMessageDismissed:(RadarInAppMessage * _Nonnull)message {
    [radarIAMDelegate onInAppMessageDismissed:message];
}

- (void)onNewInAppMessage:(RadarInAppMessage * _Nonnull)message {
    [radarIAMDelegate onNewInAppMessage:message];
}

@end
