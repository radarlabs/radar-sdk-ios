//
//  RadarAlternativeTrackingOptions.h
//  RadarSDK
//
//  Created by Kenny Hu on 10/25/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrackingOptions.h"

@interface RadarAlternativeTrackingOptions : NSObject

@property (nonnull, copy, nonatomic, readonly) NSString *type;

@property (nonnull, strong, nonatomic, readonly) RadarTrackingOptions *trackingOptions;

@property (nullable, strong, nonatomic, readonly) NSArray<NSString *> *geofenceTags;

+ (NSArray<NSDictionary *> *_Nullable)arrayForAlternativeTrackingOptions:(NSArray<RadarAlternativeTrackingOptions *> *_Nullable) alternativeTrackingOptions;
- (NSDictionary *_Nonnull)dictionaryValue;
+ (NSArray<RadarAlternativeTrackingOptions *> *_Nullable)AlternativeTrackingOptionsFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithType:(NSString *_Nonnull)type trackingOptions:(RadarTrackingOptions *_Nonnull)trackingOptions geofenceTags:(NSArray<NSString *> *_Nullable)geofenceTags;
+ (NSArray<NSString *> *_Nullable)getGeofenceTagsWithKey:(NSString *_Nonnull)key alternativeTrackingOptions:(NSArray<RadarAlternativeTrackingOptions *> *_Nullable)alternativeTrackingOptions NS_SWIFT_NAME(getGeofenceTags(key:alternativeTrackingOptions:));
+ (RadarTrackingOptions *_Nullable)getTrackingOptionsWithKey:(NSString *_Nonnull)key alternativeTrackingOptions:(NSArray<RadarAlternativeTrackingOptions *> *_Nullable)alternativeTrackingOptions NS_SWIFT_NAME(getTrackingOptions(key:alternativeTrackingOptions:));
@end
