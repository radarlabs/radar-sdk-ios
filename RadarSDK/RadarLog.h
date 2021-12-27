//
//  RadarLog.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

/**
 Represents a debug log.
 */
@interface RadarLog : NSObject

/**
 The levels for debug logs.
 */
@property (assign, nonatomic, readonly) RadarLogLevel level;

/**
 The log message.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *message;

/**
 The datetime when the log occurred on the device.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *createdAt;

- (instancetype _Nullable)initWithMessage:(NSString *_Nullable)message
                                    level:(RadarLogLevel)level;

- (NSDictionary *_Nonnull)dictionaryValue;

+ (NSArray<NSDictionary *> *_Nullable)arrayForLogs:(NSArray<RadarLog *> *_Nullable)logs;

/**
 Returns a display string for a log level.

 @param level A log level

 @return A display string for the log level.
 */
+ (NSString *)stringForLogLevel:(RadarLogLevel)level NS_SWIFT_NAME(stringForLogLevel(_:));

@end
