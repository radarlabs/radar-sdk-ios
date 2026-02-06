//
//  RadarIAMDelegate.m
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

<<<<<<< HEAD
#import <Foundation/Foundation.h>

#import "Radar-Swift.h"
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

- (RadarInAppMessageOperation)onNewInAppMessage:(RadarInAppMessage * _Nonnull)message {
    return [radarIAMDelegate onNewInAppMessage:message];
||||||| 4cc3a5b2
=======
#import "RadarInAppMessageDelegate.h"

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

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
>>>>>>> master
}

@end
