//
//  RadarSettings.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarSettings.h"
#include <Foundation/NSDictionary.h>
#include <Foundation/NSUserDefaults.h>
#include "RadarSdkConfiguration.h"
#include <objc/NSObject.h>

#import "RadarAPIClient.h"
#import "Radar+Internal.h"
#import "RadarLogger.h"
#import "RadarTripOptions.h"
#import "RadarReplayBuffer.h"
#import "RadarLogBuffer.h"
#import "RadarUtils.h"

@implementation RadarSettings

static NSString *const kPublishableKey = @"radar-publishableKey";
static NSString *const kInstallId = @"radar-installId";
static NSString *const kSessionId = @"radar-sessionId";
static NSString *const kId = @"radar-_id";
static NSString *const kUserId = @"radar-userId";
static NSString *const kDescription = @"radar-description";
static NSString *const kProduct = @"radar-product";
static NSString *const kMetadata = @"radar-metadata";
static NSString *const kAnonymous = @"radar-anonymous";
static NSString *const kTracking = @"radar-tracking";
static NSString *const kTrackingOptions = @"radar-trackingOptions";
static NSString *const kPreviousTrackingOptions = @"radar-previousTrackingOptions";
static NSString *const kRemoteTrackingOptions = @"radar-remoteTrackingOptions";
static NSString *const kClientSdkConfiguration = @"radar-clientSdkConfiguration";
static NSString *const kSdkConfiguration = @"radar-sdkConfiguration";
static NSString *const kTripOptions = @"radar-tripOptions";
static NSString *const kLogLevel = @"radar-logLevel";
static NSString *const kBeaconUUIDs = @"radar-beaconUUIDs";
static NSString *const kHost = @"radar-host";
static NSString *const kDefaultHost = @"https://api.radar.io";
static NSString *const kLastTrackedTime = @"radar-lastTrackedTime";
static NSString *const kVerifiedHost = @"radar-verifiedHost";
static NSString *const kDefaultVerifiedHost = @"https://api-verified.radar.io";
static NSString *const kLastAppOpenTime = @"radar-lastAppOpenTime";
static NSString *const kUserDebug = @"radar-userDebug";
static NSString *const kInSurveyMode = @"radar-inSurveyMode";
static NSString *const kXPlatformSDKType = @"radar-xPlatformSDKType";
static NSString *const kXPlatformSDKVersion = @"radar-xPlatformSDKVersion";
static NSString *const kInitializeOptions = @"radar-initializeOptions";
static NSString *const kUserTags = @"radar-userTags";


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

+ (NSString *)sessionId {
    return [NSString stringWithFormat:@"%.f", [[NSUserDefaults standardUserDefaults] doubleForKey:kSessionId]];
}

+ (BOOL)updateSessionId {
    double timestampSeconds = [[NSDate date] timeIntervalSince1970];
    double sessionIdSeconds = [[NSUserDefaults standardUserDefaults] doubleForKey:kSessionId];

    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
    if (sdkConfiguration.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"Flushing replays from updateSessionId()"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }
    if (timestampSeconds - sessionIdSeconds > 300) {
        [[NSUserDefaults standardUserDefaults] setDouble:timestampSeconds forKey:kSessionId];

        [Radar logOpenedAppConversion];
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"New session | sessionId = %@", [RadarSettings sessionId]]];

        return YES;
    }
    return NO;
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

+ (NSString *)__description {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kDescription];
}

+ (void)setDescription:(NSString *)description {
    [[NSUserDefaults standardUserDefaults] setObject:description forKey:kDescription];
}

+ (NSString *)product {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kProduct];
}

+ (void)setProduct:(NSString *)product {
    [[NSUserDefaults standardUserDefaults] setObject:product forKey:kProduct];
}

+ (NSDictionary *)metadata {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kMetadata];
}

+ (void)setMetadata:(NSString *)metadata {
    [[NSUserDefaults standardUserDefaults] setObject:metadata forKey:kMetadata];
}

+ (BOOL)anonymousTrackingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAnonymous];
}

+ (void)setAnonymousTrackingEnabled:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kAnonymous];
}

+ (BOOL)tracking {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kTracking];
}

+ (void)setTracking:(BOOL)tracking {
    [[NSUserDefaults standardUserDefaults] setBool:tracking forKey:kTracking];
}

+ (RadarTrackingOptions *)trackingOptions {
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kTrackingOptions];

    if (optionsDict != nil) {
        return [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    } else {
        // default to efficient preset
        return RadarTrackingOptions.presetEfficient;
    }
}

+ (void)setTrackingOptions:(RadarTrackingOptions *)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kTrackingOptions];
}

+ (void)removeTrackingOptions {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTrackingOptions];
}

+ (RadarTrackingOptions *)previousTrackingOptions {
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kPreviousTrackingOptions];

    if (optionsDict != nil) {
        return [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    } else {
        return nil;
    }
}

+ (void)setPreviousTrackingOptions:(RadarTrackingOptions *)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kPreviousTrackingOptions];
}

+ (void)removePreviousTrackingOptions {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPreviousTrackingOptions];
}

+ (RadarTrackingOptions *_Nullable)remoteTrackingOptions {
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kRemoteTrackingOptions];

    return optionsDict ? [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict] : nil;
}

+ (void)setRemoteTrackingOptions:(RadarTrackingOptions *_Nonnull)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kRemoteTrackingOptions];
}

+ (void)removeRemoteTrackingOptions {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRemoteTrackingOptions];
}

+ (RadarTripOptions *)tripOptions {
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kTripOptions];

    if (optionsDict != nil) {
        return [RadarTripOptions tripOptionsFromDictionary:optionsDict];
    } else {
        return nil;
    }
}

+ (void)setTripOptions:(RadarTripOptions *)options {
    if (options) {
        NSDictionary *optionsDict = [options dictionaryValue];
        [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kTripOptions];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTripOptions];
    }
}

+ (NSDictionary *)clientSdkConfiguration {
    NSDictionary *sdkConfigurationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kClientSdkConfiguration];
    if (sdkConfigurationDict == nil) {
        sdkConfigurationDict = [[NSDictionary alloc] init];
    } 
    return sdkConfigurationDict;
}

+ (void) setClientSdkConfiguration:(NSDictionary *)sdkConfiguration {
    if (sdkConfiguration) {
        [[NSUserDefaults standardUserDefaults] setObject:sdkConfiguration forKey:kClientSdkConfiguration];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kClientSdkConfiguration];
    }
}

+ (void)setSdkConfiguration:(RadarSdkConfiguration *)sdkConfiguration {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
        message:[NSString stringWithFormat:@"Setting SDK configuration | sdkConfiguration = %@",
                            [RadarUtils dictionaryToJson:[sdkConfiguration dictionaryValue]]]];
    if (sdkConfiguration) {
        [[RadarLogBuffer sharedInstance] setPersistentLogFeatureFlag:sdkConfiguration.useLogPersistence];
        [RadarSettings setLogLevel:sdkConfiguration.logLevel];
        [[NSUserDefaults standardUserDefaults] setObject:[sdkConfiguration dictionaryValue] forKey:kSdkConfiguration];
    } else {
        [[RadarLogBuffer sharedInstance] setPersistentLogFeatureFlag:NO];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSdkConfiguration];
    }
}

+ (RadarSdkConfiguration *_Nullable)sdkConfiguration {
    NSDictionary *sdkConfigurationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSdkConfiguration];
    return [[RadarSdkConfiguration alloc] initWithDict:sdkConfigurationDict];
}

+ (BOOL)isDebugBuild {
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

+ (RadarLogLevel)logLevel {
    RadarLogLevel defaultLogLevel;
    if ([RadarSettings userDebug]) {
        defaultLogLevel = RadarLogLevelDebug;
    } else if ([self isDebugBuild]) {
        defaultLogLevel = RadarLogLevelInfo;
    } else {
        defaultLogLevel = RadarLogLevelNone;
    }

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLogLevel] == nil) {
        return defaultLogLevel;
    } 
    return (RadarLogLevel)[[NSUserDefaults standardUserDefaults] integerForKey:kLogLevel];
}

+ (void)setLogLevel:(RadarLogLevel)level {
    [[NSUserDefaults standardUserDefaults] setInteger:(int)level forKey:kLogLevel];
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDs {
    NSArray<NSString *> *beaconUUIDs = [[NSUserDefaults standardUserDefaults] valueForKey:kBeaconUUIDs];
    return beaconUUIDs;
}

+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [[NSUserDefaults standardUserDefaults] setValue:beaconUUIDs forKey:kBeaconUUIDs];
}

+ (NSString *)host {
    //return @"https://arriving-eagle-magnetic.ngrok-free.app";
    NSString *host = [[NSUserDefaults standardUserDefaults] stringForKey:kHost];
    return host ? host : kDefaultHost;
}

+ (void)updateLastTrackedTime {
    NSDate *timeStamp = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:timeStamp forKey:kLastTrackedTime];
}

+ (NSDate *)lastTrackedTime {
    NSDate *lastTrackedTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLastTrackedTime];
    return lastTrackedTime ? lastTrackedTime : [NSDate dateWithTimeIntervalSince1970:0];
}

+ (NSString *)verifiedHost {
    NSString *verifiedHost = [[NSUserDefaults standardUserDefaults] stringForKey:kVerifiedHost];
    return verifiedHost ? verifiedHost : kDefaultVerifiedHost;
}

+ (BOOL)userDebug {
    NSNumber *userDebug = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDebug];
    return userDebug ? [userDebug boolValue] : NO;
}

+ (void)setUserDebug:(BOOL)userDebug {
    [[NSUserDefaults standardUserDefaults] setBool:userDebug forKey:kUserDebug];
}

+ (void)updateLastAppOpenTime {
    NSDate *timeStamp = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:timeStamp forKey:kLastAppOpenTime];
}

+ (NSDate *)lastAppOpenTime {
    NSDate *lastAppOpenTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLastAppOpenTime];
    return lastAppOpenTime ? lastAppOpenTime : [NSDate dateWithTimeIntervalSince1970:0];
}

+ (BOOL)useRadarModifiedBeacon {
    return [[self sdkConfiguration] useRadarModifiedBeacon];
}

+ (BOOL)xPlatform {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kXPlatformSDKType] != nil &&
    [[NSUserDefaults standardUserDefaults] stringForKey:kXPlatformSDKVersion];
}
+ (NSString *)xPlatformSDKType {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kXPlatformSDKType];
}
+ (NSString *)xPlatformSDKVersion {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kXPlatformSDKVersion];
}

+ (BOOL)useOpenedAppConversion {
    if (![self sdkConfiguration]) {
        return YES;
    }
    return [[self sdkConfiguration] useOpenedAppConversion];
}

+ (void)setInitializeOptions:(RadarInitializeOptions *)options {
    [[NSUserDefaults standardUserDefaults] setObject:[options dictionaryValue] forKey:kInitializeOptions];
}

+ (RadarInitializeOptions *)initializeOptions {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kInitializeOptions];
    if (!dict) {
        return nil;
    }
    return [[RadarInitializeOptions alloc] initWithDict:dict];
}

+ (BOOL)isInSurveyMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kInSurveyMode];
}

+ (void)setInSurveyMode:(BOOL)inSurveyMode {
    [[NSUserDefaults standardUserDefaults] setBool:inSurveyMode forKey:kInSurveyMode];
}


+ (NSArray<NSString *> *_Nullable)tags {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kUserTags];
}

+ (void)setTags:(NSArray<NSString *> *_Nullable)tags {
    if (tags) {
        [[NSUserDefaults standardUserDefaults] setObject:tags forKey:kUserTags];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserTags];
    }
}

+ (void)addTags:(NSArray<NSString *> *_Nonnull)tags {
    NSMutableArray<NSString *> *existingTags = [[self tags] mutableCopy];
    if (!existingTags) {
        existingTags = [NSMutableArray new];
    }
    
    NSSet<NSString *> *existingTagsSet = [NSSet setWithArray:existingTags];
    for (NSString *tag in tags) {
        if (![existingTagsSet containsObject:tag]) {
            [existingTags addObject:tag];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:existingTags forKey:kUserTags];
}

+ (void)removeTags:(NSArray<NSString *> *_Nonnull)tags {
    NSMutableArray<NSString *> *existingTags = [[self tags] mutableCopy];
    if (!existingTags) {
        return;
    }
    
    [existingTags removeObjectsInArray:tags];
    
    if (existingTags.count > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:existingTags forKey:kUserTags];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserTags];
    }
}

@end
