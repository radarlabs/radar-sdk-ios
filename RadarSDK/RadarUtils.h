//
//  RadarUtils.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CLLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RadarConnectionType) {
    RadarConnectionTypeUnknown,
    RadarConnectionTypeWiFi,
    RadarConnectionTypeCellular
};

@interface RadarUtils : NSObject

@property (class, nonatomic, assign, readonly) NSDateFormatter *isoDateFormatter;

+ (NSString *)deviceModel;

+ (NSString *)country;
+ (NSNumber *)timeZoneOffset;
+ (NSString *)sdkVersion;
+ (NSString *)deviceType;
+ (NSString *)deviceMake;
+ (BOOL)isSimulator;
+ (BOOL)locationBackgroundMode;
+ (NSString *)locationAuthorization;
+ (NSString *)locationAccuracyAuthorization;
+ (CLLocation *)locationForDictionary:(NSDictionary *_Nonnull)dict;
+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location;
+ (NSString *)dictionaryToJson:(NSDictionary *)dict;

+ (RadarConnectionType)networkType;
+ (NSString *)networkTypeString;

+ (NSDictionary *)appInfo;

@end

__attribute__((deprecated("Use RadarUtils for swift implementation instead, except deviceOS, deviceId, foreground, backgroundTimeRemaining, and runOnMainThread calls from Objective-C")));
@interface RadarUtilsDeprecated : RadarUtils

// These functions are async in swift, use [RadarUtilsDeprecated ...] to call them in Objective C
+ (NSString *)deviceOS;
+ (NSString *)deviceId;
+ (void)runOnMainThread:(dispatch_block_t)block;
+ (BOOL)foreground;
+ (NSTimeInterval)backgroundTimeRemaining;

@end

NS_ASSUME_NONNULL_END
