//
//  Test.mm
//  Example
//
//  Created by ShiCheng Lu on 10/27/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <RadarSDK/RadarSDK.h>

@interface TestClass : NSObject

@end

@implementation TestClass

+ (void)showInAppMessage:(NSDictionary *)inAppMessageDict {
     RadarInAppMessage *inAppMessage = [RadarInAppMessage fromDictionary:inAppMessageDict];
     if (inAppMessage != nil) {
         [Radar showInAppMessage:inAppMessage];
     }
 }

@end

