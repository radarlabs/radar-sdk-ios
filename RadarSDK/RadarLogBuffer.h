//
//  RadarLogBuffer.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLogBuffer : NSObject

@property (assign, nonatomic, readonly) NSArray<RadarLog *> *flushableLogs;

- (instancetype)init;

+ (instancetype)sharedInstance;

- (void)write:(RadarLogLevel)level message:(NSString *)message;

- (void)purgeOldestLogs;

- (void)clearSyncedLogsFromBuffer:(NSUInteger)numLogs;

@end

NS_ASSUME_NONNULL_END
