//
//  RadarRemoteTrackingOptions.h
//  RadarSDK
//
//  Created by Alan Charles on 1/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrackingOptions.h"

@interface RadarRemoteTrackingOptions : NSObject

@property (nonnull, copy, nonatomic, readonly) NSString *type;

@property (nonnull, strong, nonatomic, readonly) RadarTrackingOptions *trackingOptions;

@property (nullable, strong, nonatomic, readonly) NSArray<NSString *> *geofenceTags;

+ (NSArray<NSDictionary *> *_Nullable)arrayForRemoteTrackingOptions:(NSArray<RadarRemoteTrackingOptions *> *_Nullable) remoteTrackingOptions;
- (NSDictionary *_Nonnull)dictionaryValue;
+ (NSArray<RadarRemoteTrackingOptions *> *_Nullable)RemoteTrackingOptionsFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithType:(NSString *_Nonnull)type trackingOptions:(RadarTrackingOptions *_Nonnull)trackingOptions geofenceTags:(NSArray<NSString *> *_Nullable)geofenceTags;
+ (NSArray<NSString *> *_Nullable)getGeofenceTagsWithKey:(NSString *_Nonnull)key remoteTrackingOptions:(NSArray<RadarRemoteTrackingOptions *> *_Nullable)remoteTrackingOptions NS_SWIFT_NAME(getGeofenceTags(key:remoteTrackingOptions:));
+ (RadarTrackingOptions *_Nullable)getTrackingOptionsWithKey:(NSString *_Nonnull)key remoteTrackingOptions:(NSArray<RadarRemoteTrackingOptions *> *_Nullable)remoteTrackingOptions NS_SWIFT_NAME(getTrackingOptions(key:remoteTrackingOptions:));
@end
