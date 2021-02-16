//
//  RadarLogger.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLogger : NSObject

+ (instancetype)sharedInstance;
- (void)logWithLevel:(RadarLogLevel)level message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
