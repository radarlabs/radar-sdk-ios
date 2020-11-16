//
//  RadarSettings.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarTrackingOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarSettings : NSObject

+ (NSString *_Nullable)publishableKey;
+ (void)setPublishableKey:(NSString *)publishableKey;
+ (NSString *)installId;
+ (NSString *_Nullable)_id;
+ (void)setId:(NSString *_Nullable)_id;
+ (NSString *_Nullable)userId;
+ (void)setUserId:(NSString *_Nullable)userId;
+ (NSString *_Nullable)_description;
+ (void)setDescription:(NSString *_Nullable)_description;
+ (NSDictionary *_Nullable)metadata;
+ (void)setMetadata:(NSDictionary *_Nullable)metadata;
+ (BOOL)adIdEnabled;
+ (void)setAdIdEnabled:(BOOL)enabled;
+ (BOOL)tracking;
+ (void)setTracking:(BOOL)tracking;
+ (RadarTrackingOptions *_Nullable)trackingOptions;
+ (void)setTrackingOptions:(RadarTrackingOptions *_Nonnull)options;
+ (RadarTripOptions *_Nullable)tripOptions;
+ (void)setTripOptions:(RadarTripOptions *_Nullable)options;
+ (NSString *_Nullable)tripId;
+ (void)setTripId:(NSString *_Nullable)tripId;
+ (void)setConfig:(NSDictionary *_Nullable)config;
+ (RadarLogLevel)logLevel;
+ (void)setLogLevel:(RadarLogLevel)level;
+ (NSString *)host;

@end

NS_ASSUME_NONNULL_END
