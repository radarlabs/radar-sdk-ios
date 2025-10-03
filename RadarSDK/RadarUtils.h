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
+ (NSString *)deviceOS;
+ (NSString *)country;
+ (NSNumber *)timeZoneOffset;
+ (NSString *)sdkVersion;
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
+ (NSString *)dictionaryToJson:(NSDictionary *)dict;
+ (void)runOnMainThread:(dispatch_block_t)block;

+ (RadarConnectionType)networkType;
+ (NSString *)networkTypeString;

+ (NSDictionary *)appInfo;

@end

NS_ASSUME_NONNULL_END
