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
static NSString *const kXPlatformSDKType = @"radar-xPlatformSDKType";
static NSString *const kXPlatformSDKVersion = @"radar-xPlatformSDKVersion";

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
        [[NSUserDefaults standardUserDefaults] setInteger:(int)sdkConfiguration.logLevel forKey:kLogLevel];
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

+ (RadarLogLevel)logLevel {
    RadarLogLevel logLevel;
    if ([RadarSettings userDebug]) {
        logLevel = RadarLogLevelDebug;
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kLogLevel] == nil) {
        logLevel = RadarLogLevelInfo;
    } else {
        logLevel = (RadarLogLevel)[[NSUserDefaults standardUserDefaults] integerForKey:kLogLevel];
    }
    return logLevel;
}

+ (void)setLogLevel:(RadarLogLevel)level {
    
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDs {
    NSArray<NSString *> *beaconUUIDs = [[NSUserDefaults standardUserDefaults] valueForKey:kBeaconUUIDs];
    return beaconUUIDs;
}

+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [[NSUserDefaults standardUserDefaults] setValue:beaconUUIDs forKey:kBeaconUUIDs];
}

+ (NSString *)host {
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
    return userDebug ? [userDebug boolValue] : YES;
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

+ (BOOL)useLocationMetadata {
    return [[self sdkConfiguration] useLocationMetadata];
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

@end
