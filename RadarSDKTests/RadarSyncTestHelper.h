//
//  RadarSyncTestHelper.h
//  RadarSDK
//
//  Created by Alan Charles on 4/9/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RadarUser;

@interface RadarSyncTestHelper : NSObject
+ (void)setStopped:(BOOL)stopped;
+ (void)setRadarUser:(RadarUser *)user;
@end
