//
//  RadarUtils.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CLLocation.h>
#import <Foundation/Foundation.h>
#import "RadarSettings.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RadarConnectionType) {
    RadarConnectionTypeUnknown,
    RadarConnectionTypeWiFi,
    RadarConnectionTypeCellular
};

@interface RadarUtils : NSObject

@property (class, nonatomic, assign, readonly) NSDateFormatter *isoDateFormatter;

+ (NSString *)deviceModel;
+ (NSString *)deviceOS;
+ (NSString *)country;
+ (NSNumber *)timeZoneOffset;
+ (NSString *)sdkVersion;
+ (NSString *)deviceId;
+ (NSString *)deviceType;
+ (NSString *)deviceMake;
+ (BOOL)isSimulator;
+ (BOOL)locationBackgroundMode;
+ (NSString *)locationAuthorization;
+ (NSString *)locationAccuracyAuthorization;
+ (BOOL)foreground NS_SWIFT_NAME(foreground());
+ (NSTimeInterval)backgroundTimeRemaining;
+ (CLLocation *)locationForDictionary:(NSDictionary *_Nonnull)dict;
+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location;
+ (CLRegion *)regionForDictionary:(NSDictionary *_Nonnull)dict;
+ (NSDictionary *)dictionaryForRegion:(CLRegion *)region;
+ (NSString *)dictionaryToJson:(NSDictionary *)dict;
+ (void)runOnMainThread:(dispatch_block_t)block;
+ (BOOL)isLive NS_SWIFT_NAME(isLive());

+ (RadarConnectionType)networkType;
+ (NSString *)networkTypeString;

+ (NSDictionary *)appInfo;

@end

NS_ASSUME_NONNULL_END
