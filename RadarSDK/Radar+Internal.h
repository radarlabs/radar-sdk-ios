//
//  Radar+Internal.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"
#import <Foundation/Foundation.h>

@interface Radar ()

+ (void)sendLog:(RadarLogLevel)level message:(NSString *_Nonnull)message;

+ (void)flushLogs;

@end
