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

@end
