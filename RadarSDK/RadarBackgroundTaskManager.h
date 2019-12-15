//
//  RadarBackgroundTaskManager.h
//  RadarSDK
//
//  Created by Nick Patrick on 11/24/19.
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBackgroundTaskManager : NSObject

+ (instancetype)sharedInstance;
- (void)startBackgroundTask;
- (void)endBackgroundTasks;

@end

NS_ASSUME_NONNULL_END
