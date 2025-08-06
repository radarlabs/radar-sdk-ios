//
//  IAMDelegate.h
//  Example
//
//  Created by ShiCheng Lu on 7/23/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#ifndef IAMDelegate_h
#define IAMDelegate_h


#import "RadarSDK/RadarInAppMessageDelegate.h"

NS_SWIFT_NAME(MyObjC_IAMDelegate)
@interface MyObjC_IAMDelegate : RadarInAppMessageDelegate

//- (void)getIAMViewController:(RadarInAppMessage * _Nonnull)message completionHandler:(void (^)(UIViewController *))completionHandler;

- (void)onInAppMessageButtonClicked:(RadarInAppMessage * _Nonnull)message;

@end

#endif /* IAMDelegate_h */
