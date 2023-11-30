//
//  RadarLogBuffer.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarLog.h"
#import "RadarFileSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLogBuffer : NSObject

@property (assign, nonatomic, readonly) NSArray<RadarLog *> *flushableLogs;
@property (strong, nonatomic) NSString *logFilePath;
@property (strong, nonatomic) RadarFileSystem *fileHandler;
@property (nonatomic, strong) NSTimer *timer;

+ (instancetype)sharedInstance;

- (void)write:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message;

- (void)append:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message;

- (void)flushToPersistentStorage;

- (void)clear;

- (void)removeLogsFromBuffer:(NSUInteger)numLogs;

- (void)addLogsToBuffer:(NSArray<RadarLog *> *)logs;

@end

NS_ASSUME_NONNULL_END
