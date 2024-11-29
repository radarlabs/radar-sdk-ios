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

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIDevice *device;

+ (instancetype)sharedInstance;
- (void)logWithLevel:(RadarLogLevel)level message:(NSString *)message;
- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message;
- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message includeDate:(BOOL)includeDate includeBattery:(BOOL)includeBattery;
- (void)logWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message includeDate:(BOOL)includeDate includeBattery:(BOOL)includeBattery append:(BOOL)append;

@end

NS_ASSUME_NONNULL_END
