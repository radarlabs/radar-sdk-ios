//
//  RadarUtils.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define weakify(var) __weak typeof(var) RadarWeak_##var = var;

#define strongify(var)                                                                                                                                                             \
    _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wshadow\"") __strong typeof(var) var = RadarWeak_##var;                                                  \
    _Pragma("clang diagnostic pop")

#define strongify_else_return(var)                                                                                                                                                 \
    strongify(var);                                                                                                                                                                \
    if (!var) {                                                                                                                                                                    \
        return;                                                                                                                                                                    \
    }

NS_ASSUME_NONNULL_BEGIN

@interface RadarUtils : NSObject

+ (NSString *)deviceModel;
+ (NSString *)deviceOS;
+ (NSString *)country;
+ (NSNumber *)timeZoneOffset;
+ (NSString *)sdkVersion;
+ (NSString *)adId;
+ (NSString *)deviceId;
+ (NSString *)deviceType;
+ (NSString *)deviceMake;
+ (BOOL)locationBackgroundMode;
+ (BOOL)allowsBackgroundLocationUpdates;
+ (BOOL)foreground;
+ (NSTimeInterval)backgroundTimeRemaining;
+ (CLLocation *)locationForDictionary:(NSDictionary *_Nonnull)dict;
+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location;
+ (BOOL)validLocation:(CLLocation *)location;
+ (NSString *)uaChannelId;
+ (NSString *)uaNamedUserId;
+ (NSString *)uaSessionId;

@end

NS_ASSUME_NONNULL_END
