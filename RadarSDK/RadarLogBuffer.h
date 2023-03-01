//
//  RadarLogBuffer.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLogBuffer : NSObject

@property (assign, nonatomic, readonly) NSArray<RadarLog *> *flushableLogs;

+ (instancetype)sharedInstance;

- (void)write:(RadarLogLevel)level type:(RadarLogType *)type message:(NSString *)message;

- (void)purgeOldestLogs;

- (void)removeLogsFromBuffer:(NSUInteger)numLogs;

- (void)addLogsToBuffer:(NSArray<RadarLog *> *)logs;

@end

NS_ASSUME_NONNULL_END
