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

+ (void)logConversionWithNotification:(UNNotificationRequest *_Nonnull)request 
                            eventName:(NSString *_Nonnull)eventName
                     conversionSource:(NSString *_Nullable)conversionSource 
                       deliveredAfter:(NSDate *_Nullable)deliveredAfter;

+ (void)logOpenedAppConversionWithNotification:(UNNotificationRequest *_Nonnull)request 
                              conversionSource:(NSString *_Nullable)conversionSource;

+ (NSString *_Nonnull)stringForMotionAuthorizationStatus;

@end
