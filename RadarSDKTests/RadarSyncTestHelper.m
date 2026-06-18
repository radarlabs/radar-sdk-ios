//
//  RadarSyncTestHelper.m
//  RadarSDK
//
//  Created by Alan Charles on 4/9/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarSyncTestHelper.h"
#import "RadarState.h"

@implementation RadarSyncTestHelper
+ (void)setStopped:(BOOL)stopped { [RadarState setStopped:stopped]; }
+ (void)setRadarUser:(RadarUser *)user { [RadarState setRadarUser:user]; }
@end
