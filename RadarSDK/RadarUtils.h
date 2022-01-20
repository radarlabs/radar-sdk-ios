//
//  RadarUtils.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

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
+ (NSString *)locationAuthorization;
+ (NSString *)locationAccuracyAuthorization;
+ (BOOL)foreground;
+ (NSTimeInterval)backgroundTimeRemaining;
+ (CLLocation *)locationForDictionary:(NSDictionary *_Nonnull)dict;
+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location;
+ (BOOL)validLocation:(CLLocation *)location;

+ (void)runOnMainThread:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
