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

- (void)write:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message forcePersist:(BOOL)forcePersist;

- (void)persistLogs;

- (void)clearBuffer;

- (void)setPersistentLogFeatureFlag:(BOOL)persistentLogFeatureFlag;

- (void)onFlush:(BOOL)success logs:(NSArray<RadarLog *> *)logs;

@end

NS_ASSUME_NONNULL_END
