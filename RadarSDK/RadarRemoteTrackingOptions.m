//
//  RadarRemoteTrackingOptions.m
//  RadarSDK
//
//  Created by Alan Charles on 1/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarRemoteTrackingOptions.h"

@implementation RadarRemoteTrackingOptions
+ (NSArray<RadarRemoteTrackingOptions *> * _Nullable)RemoteTrackingOptionsFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray *mutableRemoteTrackingOptions = [NSMutableArray new];
    NSArray *remoteTrackingOptions = (NSArray *)object;
    for (id remoteTrackingOptionObj in remoteTrackingOptions) {
        RadarRemoteTrackingOptions *remoteTrackingOption = [[RadarRemoteTrackingOptions alloc] initWithObject:remoteTrackingOptionObj];
        if (remoteTrackingOption) {
            [mutableRemoteTrackingOptions addObject:remoteTrackingOption];
        }
    }
    return mutableRemoteTrackingOptions;
}

+ (NSArray<NSDictionary *> * _Nullable)arrayForRemoteTrackingOptions:(NSArray<RadarRemoteTrackingOptions *> * _Nullable)remoteTrackingOptions {
    if (!remoteTrackingOptions) {
        return nil;
    }
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:remoteTrackingOptions.count];
    for (RadarRemoteTrackingOptions *remoteTrackingOption in remoteTrackingOptions) {
        [arr addObject:[remoteTrackingOption dictionaryValue]];
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

    return [[RadarRemoteTrackingOptions alloc] initWithType:type trackingOptions:trackingOptions geofenceTags:geofenceTags];
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

+ (NSArray<NSString *> *)getGeofenceTagsWithKey:(NSString *)key remoteTrackingOptions:(NSArray<RadarRemoteTrackingOptions *> *)remoteTrackingOptions {
    if (remoteTrackingOptions == nil) {
        return nil;
    }
    for (RadarRemoteTrackingOptions *remoteTrackingOption in remoteTrackingOptions) {
        if (remoteTrackingOption == nil) {
            continue;
        }
        if ([remoteTrackingOption.type isEqualToString:key]) {
            return remoteTrackingOption.geofenceTags;
        }
    }
    return nil;
}

+ (RadarTrackingOptions *)getTrackingOptionsWithKey:(NSString *)key remoteTrackingOptions:(NSArray<RadarRemoteTrackingOptions *> *)remoteTrackingOptions {
    if (remoteTrackingOptions == nil) {
        return nil;
    }
    for (RadarRemoteTrackingOptions *remoteTrackingOption in remoteTrackingOptions) {
        if (remoteTrackingOption == nil) {
            continue;
        }
        if ([remoteTrackingOption.type isEqualToString:key]) {
            return remoteTrackingOption.trackingOptions;
        }
    }
    return nil;
}

@end
