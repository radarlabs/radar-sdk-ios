//
//  RadarLogBuffer.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarLog.h"
#import "RadarFileStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLogBuffer : NSObject

@property (assign, nonatomic, readonly) NSArray<RadarLog *> *flushableLogs;
@property (strong, nonatomic) NSString *logFileDir;
@property (strong, nonatomic) RadarFileStorage *fileHandler;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL persistentLogFeatureFlag;

+ (instancetype)sharedInstance;

- (void)write:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message;

- (void)append:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message;

- (void)persistLogs;

- (void)clearBuffer;

- (void)removeLogsFromBuffer:(NSUInteger)numLogs;

- (void)addLogsToBuffer:(NSArray<RadarLog *> *)logs;

- (void)setPersistentLogFeatureFlag:(BOOL)persistentLogFeatureFlag;

@end

NS_ASSUME_NONNULL_END
