//
//  RadarSyncTestHelper.h
//  RadarSDK
//
//  Created by Alan Charles on 4/9/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarAPIClient.h"

@class RadarUser;

@interface RadarSyncTestHelper : NSObject
+ (void)setStopped:(BOOL)stopped;
+ (void)setRadarUser:(RadarUser *)user;
@end

// Exercise the Objective-C call site without importing a duplicate Swift class declaration.
@interface RadarTrackTestBridge : NSObject
+ (void)trackWithPreparer:(NSObject *_Nonnull)preparer
                verified:(BOOL)verified
               secondary:(BOOL)secondary
              completion:(RadarTrackAPICompletionHandler)completion;
@end
