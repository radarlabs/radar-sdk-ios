//
//  RadarAlternativeTrackingOptions.m
//  RadarSDK
//
//  Created by Kenny Hu on 10/25/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarAlternativeTrackingOptions.h"

@implementation RadarAlternativeTrackingOptions
+ (NSArray<RadarAlternativeTrackingOptions *> * _Nullable)AlternativeTrackingOptionsFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray *mutableAlternativeTrackingOptions = [NSMutableArray new];
    NSArray *alternativeTrackingOptions = (NSArray *)object;
    for (id alternativeTrackingOptionObj in alternativeTrackingOptions) {
        RadarAlternativeTrackingOptions *alternativeTrackingOption = [[RadarAlternativeTrackingOptions alloc] initWithObject:alternativeTrackingOptionObj];
        if (alternativeTrackingOption) {
            [mutableAlternativeTrackingOptions addObject:alternativeTrackingOption];
        }
    }
    return mutableAlternativeTrackingOptions;
}

+ (NSArray<NSDictionary *> * _Nullable)arrayForAlternativeTrackingOptions:(NSArray<RadarAlternativeTrackingOptions *> * _Nullable)alternativeTrackingOptions {
    if (!alternativeTrackingOptions) {
        return nil;
    }
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:alternativeTrackingOptions.count];
    for (RadarAlternativeTrackingOptions *alternativeTrackingOption in alternativeTrackingOptions) {
        [arr addObject:[alternativeTrackingOption dictionaryValue]];
    }
    return arr;
}

- (NSDictionary * _Nonnull)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"type"] = self.type;
    dict[@"trackingOptions"] = [self.trackingOptions dictionaryValue];
    if (self.geofenceTags) {
        dict[@"geofenceTags"] = self.geofenceTags;
    }
    return dict;
}

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
        if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *type;
    RadarTrackingOptions *trackingOptions;
    NSArray<NSString *> *geofenceTags;

    id typeObj = dict[@"type"];
    if ([typeObj isKindOfClass:[NSString class]]) {
        type = (NSString *)typeObj;
    }

    id trackingOptionsObj = dict[@"trackingOptions"];
    if ([trackingOptionsObj isKindOfClass:[NSDictionary class]]) {
        trackingOptions = [RadarTrackingOptions trackingOptionsFromObject:trackingOptionsObj];
    }

    id geofenceTagsObj = dict[@"geofenceTags"];
    if ([geofenceTagsObj isKindOfClass:[NSArray class]]) {
        geofenceTags = (NSArray *)geofenceTagsObj;
    }

    return [[RadarAlternativeTrackingOptions alloc] initWithType:type trackingOptions:trackingOptions geofenceTags:geofenceTags];
}

- (instancetype _Nullable)initWithType:(NSString * _Nonnull)type trackingOptions:(RadarTrackingOptions * _Nonnull)trackingOptions geofenceTags:(NSArray<NSString *> * _Nullable)geofenceTags {
    self = [super init];
    if (self) {
        _type = type;
        _trackingOptions = trackingOptions;
        _geofenceTags = geofenceTags;
    }
    return self;
}

+ (NSArray<NSString *> *)getGeofenceTagsWithKey:(NSString *)key alternativeTrackingOptions:(NSArray<RadarAlternativeTrackingOptions *> *)alternativeTrackingOptions {
    if (alternativeTrackingOptions == nil) {
        return nil;
    }
    for (RadarAlternativeTrackingOptions *alternativeTrackingOption in alternativeTrackingOptions) {
        if (alternativeTrackingOption == nil) {
            continue;
        }
        if ([alternativeTrackingOption.type isEqualToString:key]) {
            return alternativeTrackingOption.geofenceTags;
        }
    }
    return nil;
}

+ (RadarTrackingOptions *)getTrackingOptionsWithKey:(NSString *)key alternativeTrackingOptions:(NSArray<RadarAlternativeTrackingOptions *> *)alternativeTrackingOptions {
    if (alternativeTrackingOptions == nil) {
        return nil;
    }
    for (RadarAlternativeTrackingOptions *alternativeTrackingOption in alternativeTrackingOptions) {
        if (alternativeTrackingOption == nil) {
            continue;
        }
        if ([alternativeTrackingOption.type isEqualToString:key]) {
            return alternativeTrackingOption.trackingOptions;
        }
    }
    return nil;
}

@end

