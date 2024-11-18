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
@interface RadarLog : NSObject <NSCoding, NSSecureCoding>

/**
 The levels for debug logs.
 */
@property (assign, nonatomic, readonly) RadarLogLevel level;

/**
 The log message.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *message;

/**
 The log type.
 */
@property (assign, nonatomic, readonly) RadarLogType type;

/**
 The datetime when the log occurred on the device.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *createdAt;

- (instancetype _Nullable)initWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *_Nullable)message;

- (NSDictionary *_Nonnull)dictionaryValue;

+ (NSArray<NSDictionary *> *_Nullable)arrayForLogs:(NSArray<RadarLog *> *_Nullable)logs;

/**
 Returns a display string for a log level.

 @param level A log level

 @return A display string for the log level.
 */
+ (NSString *_Nonnull)stringForLogLevel:(RadarLogLevel)level NS_SWIFT_NAME(stringForLogLevel(_:));

/**
 Return the log level for a specific display string
 
 @param string A display string for the log level

 @return A log level.
*/
+ (RadarLogLevel) levelFromString:(NSString *_Nonnull) string;

@end
