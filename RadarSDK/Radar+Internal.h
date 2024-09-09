//
//  Radar+Internal.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"
#import <Foundation/Foundation.h>

@interface Radar ()

+ (void)sendLog:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *_Nonnull)message;

+ (void)flushLogs;

+ (void)logOpenedAppConversion;

+ (void)logConversionWithNotification:(UNNotificationRequest *)request 
                            eventName:(NSString *)eventName
                     conversionSource:(NSString *_Nullable)conversionSource 
                       deliveredAfter:(NSDate *_Nullable)deliveredAfter;

+ (void)logOpenedAppConversionWithNotification:(UNNotificationRequest *)request 
                              conversionSource:(NSString *_Nullable)conversionSource;

@end
