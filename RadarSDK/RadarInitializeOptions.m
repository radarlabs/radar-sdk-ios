//
//  RadarInitializeOptions.m
//  RadarSDK
//
//  Created by Kenny Hu on 9/10/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarInitializeOptions.h"


@implementation RadarInitializeOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _autoSetupNotificationConversion = NO;
    }
    return self;
}

@end
