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

- (instancetype)init;

+ (instancetype)sharedInstance;

- (void)write:(RadarLogLevel)level message:(NSString *)message;

- (NSArray<RadarLog *> *)getFlushableLogs;

@end

NS_ASSUME_NONNULL_END
