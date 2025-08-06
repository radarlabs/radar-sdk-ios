//
//  IAMDelegate.m
//  Example
//
//  Created by ShiCheng Lu on 7/23/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IAMDelegate.h"

@implementation MyObjC_IAMDelegate

- (void)onInAppMessageButtonClicked:(RadarInAppMessage *)message {
    NSLog(@"onIAMPositiveAction ObjC");
}

@end
