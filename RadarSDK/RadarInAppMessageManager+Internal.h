//
//  RadarInAppMessageManager+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarInAppMessage.h"
#import "RadarInAppMessageDelegate.h"

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift RadarInAppMessageManager for Objective-C callers, since internal Swift
// classes are not emitted into RadarSDK-Swift.h. Must be called on the main thread.
@interface RadarInAppMessageManager : NSObject

@property (class, readonly, strong) RadarInAppMessageManager *shared;

- (void)showInAppMessage:(RadarInAppMessage *)message completionHandler:(void (^)(void))completionHandler;

- (void)onInAppMessageReceivedWithMessages:(NSArray<RadarInAppMessage *> *)messages;

- (void)setDelegate:(id<RadarInAppMessageProtocol>)delegate;

@end

NS_ASSUME_NONNULL_END
