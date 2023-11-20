//
//  RadarLogger.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLogger : NSObject

@property  (assign) NSString *logFilePath;

+ (instancetype)sharedInstance;
- (void)logWithLevel:(RadarLogLevel)level message:(NSString *)message;
- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message;
- (void)logWithLevelLocal:(RadarLogLevel)level message:(NSString *)message;
- (void)logWithLevelLocal:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message;
- (void)flushLocalLogs;
@end

NS_ASSUME_NONNULL_END
