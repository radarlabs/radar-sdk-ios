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
+ (void)trackWithPayload:(NSString *_Nullable)payload
                verified:(BOOL)verified
               secondary:(BOOL)secondary
                 headers:(NSDictionary<NSString *, NSString *> *_Nullable)headers
               installId:(NSString *_Nullable)installId
              completion:(RadarTrackAPICompletionHandler)completion;
@end
