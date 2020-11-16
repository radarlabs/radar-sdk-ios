//
//  RadarSettings.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarSettings.h"

#import "RadarTripOptions.h"

@implementation RadarSettings

static NSString *const kPublishableKey = @"radar-publishableKey";
static NSString *const kInstallId = @"radar-installId";
static NSString *const kId = @"radar-_id";
static NSString *const kUserId = @"radar-userId";
static NSString *const kDescription = @"radar-description";
static NSString *const kMetadata = @"radar-metadata";
static NSString *const kAdIdEnabled = @"radar-adIdEnabled";
static NSString *const kTracking = @"radar-tracking";
static NSString *const kTrackingOptions = @"radar-trackingOptions";
static NSString *const kTripOptions = @"radar-tripOptions";
static NSString *const kTripId = @"radar-tripId";
static NSString *const kLogLevel = @"radar-logLevel";
static NSString *const kConfig = @"radar-config";
static NSString *const kHost = @"radar-host";
static NSString *const kDefaultHost = @"https://api.radar.io";

+ (NSString *)publishableKey {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kPublishableKey];
}

+ (void)setPublishableKey:(NSString *)publishableKey {
    [[NSUserDefaults standardUserDefaults] setObject:publishableKey forKey:kPublishableKey];
}

+ (NSString *)installId {
    NSString *installId = [[NSUserDefaults standardUserDefaults] stringForKey:kInstallId];
    if (!installId) {
        installId = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:installId forKey:kInstallId];
    }
    return installId;
}

+ (NSString *)_id {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kId];
}

+ (void)setId:(NSString *)_id {
    [[NSUserDefaults standardUserDefaults] setObject:_id forKey:kId];
}

+ (NSString *)userId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserId];
}

+ (void)setUserId:(NSString *)userId {
    NSString *oldUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kUserId];
    if (oldUserId && ![oldUserId isEqualToString:userId]) {
        [RadarSettings setId:nil];
    }
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:kUserId];
}

+ (NSString *)_description {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kDescription];
}

+ (void)setDescription:(NSString *)_description {
    [[NSUserDefaults standardUserDefaults] setObject:_description forKey:kDescription];
}

+ (NSDictionary *)metadata {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kMetadata];
}

+ (void)setMetadata:(NSString *)metadata {
    [[NSUserDefaults standardUserDefaults] setObject:metadata forKey:kMetadata];
}

+ (BOOL)adIdEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAdIdEnabled];
}

+ (void)setAdIdEnabled:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kAdIdEnabled];
}

+ (BOOL)tracking {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kTracking];
}

+ (void)setTracking:(BOOL)tracking {
    [[NSUserDefaults standardUserDefaults] setBool:tracking forKey:kTracking];
}

+ (RadarTrackingOptions *)trackingOptions {
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kTrackingOptions];
    return [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
}

+ (void)setTrackingOptions:(RadarTrackingOptions *)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kTrackingOptions];
}

+ (RadarTripOptions *)tripOptions {
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kTripOptions];
    return [RadarTripOptions tripOptionsFromDictionary:optionsDict];
}

+ (void)setTripOptions:(RadarTripOptions *)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kTripOptions];
}

+ (NSString *)tripId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kTripId];
}

+ (void)setTripId:(NSString *)tripId {
    [[NSUserDefaults standardUserDefaults] setObject:tripId forKey:kTripId];
}

+ (void)setConfig:(NSDictionary *)config {
    [[NSUserDefaults standardUserDefaults] setObject:config forKey:kConfig];
}

+ (RadarLogLevel)logLevel {
    NSInteger logLevelInteger = [[NSUserDefaults standardUserDefaults] integerForKey:kLogLevel];
    return (RadarLogLevel)logLevelInteger;
}

+ (void)setLogLevel:(RadarLogLevel)level {
    NSInteger logLevelInteger = (int)level;
    [[NSUserDefaults standardUserDefaults] setInteger:logLevelInteger forKey:kLogLevel];
}

+ (NSString *)host {
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:kHost];
    return host ? host : kDefaultHost;
}

@end
