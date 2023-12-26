//
//  RadarSettings.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarSettings.h"

#import "Radar+Internal.h"
#import "RadarLogger.h"
#import "RadarTripOptions.h"
#import "RadarFeatureSettings.h"
#import "RadarReplayBuffer.h"
#import "RadarLogBuffer.h"
#import "RadarUserDefaults.h"

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
static NSString *const kFeatureSettings = @"radar-featureSettings";
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

+ (void) migrateIfNeeded {
    if (![RadarUserDefaults sharedInstance].migrationCompleteFlag) {
        [self setPublishableKey:[[NSUserDefaults standardUserDefaults] stringForKey:kPublishableKey]];
        [[RadarUserDefaults sharedInstance] setObject:[[NSUserDefaults standardUserDefaults] stringForKey:kInstallId] forKey:kInstallId];
        [[RadarUserDefaults sharedInstance] setDouble:[[NSUserDefaults standardUserDefaults] doubleForKey:kSessionId] forKey:kSessionId];
        [self setId:[[NSUserDefaults standardUserDefaults] stringForKey:kId]];
        [self setUserId:[[NSUserDefaults standardUserDefaults] stringForKey:kUserId]];
        [self setDescription:[[NSUserDefaults standardUserDefaults] stringForKey:kDescription]];
        [self setMetadata:[[NSUserDefaults standardUserDefaults] stringForKey:kMetadata]];
        [self setAnonymousTrackingEnabled:[[NSUserDefaults standardUserDefaults] boolForKey:kAnonymous]];
        [self setTracking:[[NSUserDefaults standardUserDefaults] boolForKey:kTracking]];
        [self setTrackingOptions:[RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:kTrackingOptions]]];
        [self setPreviousTrackingOptions:[RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:kPreviousTrackingOptions]]];
        [self setRemoteTrackingOptions:[RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:kRemoteTrackingOptions]]];
        [self setTripOptions:[RadarTripOptions tripOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:kTripOptions]]];
        [self setFeatureSettings:[RadarFeatureSettings featureSettingsFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:kFeatureSettings]]];
        [self setLogLevel:[[NSUserDefaults standardUserDefaults] integerForKey:kLogLevel]];
        [self setBeaconUUIDs:[[NSUserDefaults standardUserDefaults] arrayForKey:kBeaconUUIDs]];
        [self setHost:[[NSUserDefaults standardUserDefaults] stringForKey:kHost]];
        [self setVerifiedHost:[[NSUserDefaults standardUserDefaults] stringForKey:kVerifiedHost]];
        [self setUserDebug:[[NSUserDefaults standardUserDefaults] boolForKey:kUserDebug]];
        [[RadarUserDefaults sharedInstance] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kLastTrackedTime] forKey:kLastTrackedTime]; 
        [[RadarUserDefaults sharedInstance] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kLastAppOpenTime] forKey:kLastAppOpenTime]; 
        [RadarUserDefaults sharedInstance setMigrationCompleteFlag: YES];
    }
}



+ (NSString *)publishableKey {
    return [[RadarUserDefaults sharedInstance] stringForKey:kPublishableKey];
}

+ (void)setPublishableKey:(NSString *)publishableKey {
    [[RadarUserDefaults sharedInstance] setObject:publishableKey forKey:kPublishableKey];
}

+ (NSString *)installId {
    NSString *installId = [[RadarUserDefaults sharedInstance] stringForKey:kInstallId];
    if (!installId) {
        installId = [[NSUUID UUID] UUIDString];
        [[RadarUserDefaults sharedInstance] setObject:installId forKey:kInstallId];
    }
    return installId;
}

+ (NSString *)sessionId {
    return [NSString stringWithFormat:@"%.f", [[RadarUserDefaults sharedInstance] doubleForKey:kSessionId]];
}

+ (BOOL)updateSessionId {
    double timestampSeconds = [[NSDate date] timeIntervalSince1970];
    double sessionIdSeconds = [[RadarUserDefaults sharedInstance] doubleForKey:kSessionId];

    RadarFeatureSettings *featureSettings = [RadarSettings featureSettings];
    if (featureSettings.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"flushReplays() from updateSesssionId"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }
    if (timestampSeconds - sessionIdSeconds > 300) {
        [[RadarUserDefaults sharedInstance] setDouble:timestampSeconds forKey:kSessionId];

        [Radar logOpenedAppConversion];
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"New session | sessionId = %@", [RadarSettings sessionId]]];

        return YES;
    }
    return NO;
}

+ (NSString *)_id {
    return [[RadarUserDefaults sharedInstance] stringForKey:kId];
}

+ (void)setId:(NSString *)_id {
    [[RadarUserDefaults sharedInstance] setObject:_id forKey:kId];
}

+ (NSString *)userId {
    return [[RadarUserDefaults sharedInstance] stringForKey:kUserId];
}

+ (void)setUserId:(NSString *)userId {
    NSString *oldUserId = [[RadarUserDefaults sharedInstance] stringForKey:kUserId];
    if (oldUserId && ![oldUserId isEqualToString:userId]) {
        [RadarSettings setId:nil];
    }
    [[RadarUserDefaults sharedInstance] setObject:userId forKey:kUserId];
}

+ (NSString *)__description {
    return [[RadarUserDefaults sharedInstance] stringForKey:kDescription];
}

+ (void)setDescription:(NSString *)description {
    [[RadarUserDefaults sharedInstance] setObject:description forKey:kDescription];
}

+ (NSDictionary *)metadata {
    return [[RadarUserDefaults sharedInstance] dictionaryForKey:kMetadata];
}

+ (void)setMetadata:(NSString *)metadata {
    [[RadarUserDefaults sharedInstance] setObject:metadata forKey:kMetadata];
}

+ (BOOL)anonymousTrackingEnabled {
    return [[RadarUserDefaults sharedInstance] boolForKey:kAnonymous];
}

+ (void)setAnonymousTrackingEnabled:(BOOL)enabled {
    [[RadarUserDefaults sharedInstance] setBool:enabled forKey:kAnonymous];
}

+ (BOOL)tracking {
    return [[RadarUserDefaults sharedInstance] boolForKey:kTracking];
}

+ (void)setTracking:(BOOL)tracking {
    [[RadarUserDefaults sharedInstance] setBool:tracking forKey:kTracking];
}

+ (RadarTrackingOptions *)trackingOptions {
    NSDictionary *optionsDict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kTrackingOptions];

    if (optionsDict != nil) {
        return [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    } else {
        // default to efficient preset
        return RadarTrackingOptions.presetEfficient;
    }
}

+ (void)setTrackingOptions:(RadarTrackingOptions *)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[RadarUserDefaults sharedInstance] setObject:optionsDict forKey:kTrackingOptions];
}

+ (void)removeTrackingOptions {
    [[RadarUserDefaults sharedInstance] removeObjectForKey:kTrackingOptions];
}

+ (RadarTrackingOptions *)previousTrackingOptions {
    NSDictionary *optionsDict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kPreviousTrackingOptions];

    if (optionsDict != nil) {
        return [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    } else {
        return nil;
    }
}

+ (void)setPreviousTrackingOptions:(RadarTrackingOptions *)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[RadarUserDefaults sharedInstance] setObject:optionsDict forKey:kPreviousTrackingOptions];
}

+ (void)removePreviousTrackingOptions {
    [[RadarUserDefaults sharedInstance] removeObjectForKey:kPreviousTrackingOptions];
}

+ (RadarTrackingOptions *_Nullable)remoteTrackingOptions {
    NSDictionary *optionsDict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kRemoteTrackingOptions];

    return optionsDict ? [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict] : nil;
}

+ (void)setRemoteTrackingOptions:(RadarTrackingOptions *_Nonnull)options {
    NSDictionary *optionsDict = [options dictionaryValue];
    [[RadarUserDefaults sharedInstance] setObject:optionsDict forKey:kRemoteTrackingOptions];
}

+ (void)removeRemoteTrackingOptions {
    [[RadarUserDefaults sharedInstance] removeObjectForKey:kRemoteTrackingOptions];
}

+ (RadarTripOptions *)tripOptions {
    NSDictionary *optionsDict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kTripOptions];

    if (optionsDict != nil) {
        return [RadarTripOptions tripOptionsFromDictionary:optionsDict];
    } else {
        return nil;
    }
}

+ (void)setTripOptions:(RadarTripOptions *)options {
    if (options) {
        NSDictionary *optionsDict = [options dictionaryValue];
        [[RadarUserDefaults sharedInstance] setObject:optionsDict forKey:kTripOptions];
    } else {
        [[RadarUserDefaults sharedInstance] removeObjectForKey:kTripOptions];
    }
}

+ (RadarFeatureSettings *)featureSettings {
    NSDictionary *featureSettingsDict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kFeatureSettings];

    return [RadarFeatureSettings featureSettingsFromDictionary:featureSettingsDict];
}

+ (void)setFeatureSettings:(RadarFeatureSettings *)featureSettings {
    if (featureSettings) {
        //This is added as reading from NSUserdefaults is too slow for this feature flag. To be removed when throttling is done. 
        [[RadarLogBuffer sharedInstance] setFeatureFlag:featureSettings.useLogPersistence];
        NSDictionary *featureSettingsDict = [featureSettings dictionaryValue];
        [[RadarUserDefaults sharedInstance] setObject:featureSettingsDict forKey:kFeatureSettings];
    } else {
        //This is added as reading from NSUserdefaults is too slow for this feature flag. To be removed when throttling is done. 
        [[RadarLogBuffer sharedInstance] setFeatureFlag:NO];
        [[RadarUserDefaults sharedInstance] removeObjectForKey:kFeatureSettings];
    }
}


+ (RadarLogLevel)logLevel {
    RadarLogLevel logLevel;
    if ([RadarSettings userDebug]) {
        logLevel = RadarLogLevelDebug;
    } else if ([[RadarUserDefaults sharedInstance] objectForKey:kLogLevel] == nil) {
        logLevel = RadarLogLevelInfo;
    } else {
        logLevel = (RadarLogLevel)[[RadarUserDefaults sharedInstance] integerForKey:kLogLevel];
    }
    return logLevel;
}

+ (void)setLogLevel:(RadarLogLevel)level {
    NSInteger logLevelInteger = (int)level;
    [[RadarUserDefaults sharedInstance] setInteger:logLevelInteger forKey:kLogLevel];
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDs {
    NSArray<NSString *> *beaconUUIDs = [[RadarUserDefaults sharedInstance] valueForKey:kBeaconUUIDs];
    return beaconUUIDs;
}

+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [[RadarUserDefaults sharedInstance] setValue:beaconUUIDs forKey:kBeaconUUIDs];
}

+ (NSString *)host {
    NSString *host = [[RadarUserDefaults sharedInstance] stringForKey:kHost];
    return host ? host : kDefaultHost;
}

+ (void)updateLastTrackedTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarUserDefaults sharedInstance] setObject:timeStamp forKey:kLastTrackedTime];
}

+ (NSDate *)lastTrackedTime {
    NSDate *lastTrackedTime = [[RadarUserDefaults sharedInstance] objectForKey:kLastTrackedTime];
    return lastTrackedTime ? lastTrackedTime : [NSDate dateWithTimeIntervalSince1970:0];
}

+ (NSString *)verifiedHost {
    NSString *verifiedHost = [[RadarUserDefaults sharedInstance] stringForKey:kVerifiedHost];
    return verifiedHost ? verifiedHost : kDefaultVerifiedHost;
}

+ (BOOL)userDebug {
    NSNumber *userDebug = [[RadarUserDefaults sharedInstance] objectForKey:kUserDebug];
    return userDebug ? [userDebug boolValue] : YES;
}

+ (void)setUserDebug:(BOOL)userDebug {
    [[RadarUserDefaults sharedInstance] setBool:userDebug forKey:kUserDebug];
}

+ (void)updateLastAppOpenTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarUserDefaults sharedInstance] setObject:timeStamp forKey:kLastAppOpenTime];
}

+ (NSDate *)lastAppOpenTime {
    NSDate *lastAppOpenTime = [[RadarUserDefaults sharedInstance] objectForKey:kLastAppOpenTime];
    return lastAppOpenTime ? lastAppOpenTime : [NSDate dateWithTimeIntervalSince1970:0];
}

@end
