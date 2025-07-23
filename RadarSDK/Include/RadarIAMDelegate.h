//
//  RadarIAMDelegate.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/23/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RadarInAppMessage;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RadarIAMDelegate_ObjC)
API_AVAILABLE(ios(13.0))
NS_SWIFT_UI_ACTOR
@interface RadarIAMDelegate : NSObject

- (instancetype) init;

- (void)getIAMViewController:(RadarInAppMessage * _Nonnull)message completionHandler:(void (^)(UIViewController *))completionHandler;

- (void)onIAMPositiveAction:(RadarInAppMessage * _Nonnull)message;

@end

NS_ASSUME_NONNULL_END
