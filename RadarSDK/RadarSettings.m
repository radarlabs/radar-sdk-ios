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
#import "RadarKVStore.h"
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

+ (void) migrateToRadarKVStore {

    NSMutableArray<NSString *> *migrationResultArray = [[NSMutableArray alloc] init];

    NSString *publishableKey = [[NSUserDefaults standardUserDefaults] stringForKey:kPublishableKey];
    [self setPublishableKey:publishableKey];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated publishableKey: %@", publishableKey]];

    NSString *installId = [[NSUserDefaults standardUserDefaults] stringForKey:kInstallId];
    [[RadarKVStore sharedInstance] setObject:installId forKey:kInstallId];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated installId: %@", installId]];

    double sessionId = [[NSUserDefaults standardUserDefaults] doubleForKey:kSessionId];
    [[RadarKVStore sharedInstance] setDouble:sessionId forKey:kSessionId];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated sessionId: %f", sessionId]];

    NSString *_id = [[NSUserDefaults standardUserDefaults] stringForKey:kId];
    [self setId:_id];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated _id: %@", _id]];

    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:kUserId];
    [self setUserId:userId];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated userId: %@", userId]];

    NSString *description = [[NSUserDefaults standardUserDefaults] stringForKey:kDescription];
    [self setDescription:description];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated description: %@", description]];

    NSObject *metadata = [[NSUserDefaults standardUserDefaults] objectForKey:kMetadata];
    [self setMetadata:(NSDictionary *)metadata];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated metadata: %@", [RadarUtils dictionaryToJson:(NSDictionary *)metadata]]];
    
    BOOL anonymous = [[NSUserDefaults standardUserDefaults] boolForKey:kAnonymous];
    [self setAnonymousTrackingEnabled:anonymous];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated anonymous: %@", anonymous ? @"YES" : @"NO"]];

    BOOL tracking = [[NSUserDefaults standardUserDefaults] boolForKey:kTracking];
    [self setTracking:tracking];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated tracking: %@", tracking ? @"YES" : @"NO"]];

    RadarTrackingOptions *trackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kTrackingOptions]];
    [self setTrackingOptions:trackingOptions];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated trackingOptions: %@", [RadarUtils dictionaryToJson:[trackingOptions dictionaryValue]]]];

    RadarTrackingOptions *previousTrackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kPreviousTrackingOptions]];
    [self setPreviousTrackingOptions:previousTrackingOptions];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated previousTrackingOptions: %@", [RadarUtils dictionaryToJson:[previousTrackingOptions dictionaryValue]]]];

    RadarTrackingOptions *remoteTrackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kRemoteTrackingOptions]];
    [self setRemoteTrackingOptions:remoteTrackingOptions];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated remoteTrackingOptions: %@", [RadarUtils dictionaryToJson:[remoteTrackingOptions dictionaryValue]]]];
    
    
    RadarTripOptions *tripOptions = [RadarTripOptions tripOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kTripOptions]];
    [self setTripOptions:tripOptions];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated tripOptions: %@", [RadarUtils dictionaryToJson:[tripOptions dictionaryValue]]]];
    
    
    RadarFeatureSettings *featureSettings = [RadarFeatureSettings featureSettingsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kFeatureSettings]];
    [self setFeatureSettings:featureSettings];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated featureSettings: %@", [RadarUtils dictionaryToJson:[featureSettings dictionaryValue]]]];
    
    RadarLogLevel logLevel;
    if ([RadarSettings userDebug]) {
        logLevel = RadarLogLevelDebug;
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kLogLevel] == nil) {
        logLevel = RadarLogLevelInfo;
    } else {
        logLevel = (RadarLogLevel)[[NSUserDefaults standardUserDefaults] integerForKey:kLogLevel];
    }
    [self setLogLevel:logLevel];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated logLevel: %ld", (long)logLevel]];


    NSArray<NSString *> *beaconUUIDs = [[NSUserDefaults standardUserDefaults] valueForKey:kBeaconUUIDs];
    [self setBeaconUUIDs:beaconUUIDs];
    NSString *beaconUUIDsString = [beaconUUIDs componentsJoinedByString:@","];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated beaconUUIDs: %@", beaconUUIDsString]];
    
    NSString *host = [[NSUserDefaults standardUserDefaults] valueForKey:kHost];
    [[RadarKVStore sharedInstance] setObject:host forKey:kHost];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated host: %@", host]];

    NSString *verifiedHost = [[NSUserDefaults standardUserDefaults] valueForKey:kVerifiedHost];
    [[RadarKVStore sharedInstance] setObject:verifiedHost forKey:kVerifiedHost];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated verifiedHost: %@", verifiedHost]];

    BOOL userDebug = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDebug];
    [self setUserDebug:userDebug];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated userDebug: %@", userDebug ? @"YES" : @"NO"]];
    
    NSDate *lastTrackedTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLastTrackedTime];
    [[RadarKVStore sharedInstance] setObject:lastTrackedTime forKey:kLastTrackedTime];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated lastTrackedTime: %@", lastTrackedTime]];

    NSDate *lastAppOpenTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLastAppOpenTime];
    [[RadarKVStore sharedInstance] setObject:lastAppOpenTime forKey:kLastAppOpenTime];
    [migrationResultArray addObject:[NSString stringWithFormat:@"migrated lastAppOpenTime: %@", lastAppOpenTime]];

    NSString *migrationResultString = [migrationResultArray componentsJoinedByString:@"\n"];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Migration of RadarSetting: %@", migrationResultString]];
}

+ (NSString *)publishableKey {
    return [[RadarKVStore sharedInstance] stringForKey:kPublishableKey];
}

+ (void)setPublishableKey:(NSString *)publishableKey {
    [[RadarKVStore sharedInstance] setObject:publishableKey forKey:kPublishableKey];
}

+ (NSString *)installId {
    NSString *installId = [[RadarKVStore sharedInstance] stringForKey:kInstallId];
    if (!installId) {
        installId = [[NSUUID UUID] UUIDString];
        [[RadarKVStore sharedInstance] setObject:installId forKey:kInstallId];
    }
    return installId;
}

+ (NSString *)sessionId {
    return [NSString stringWithFormat:@"%.f", [[RadarKVStore sharedInstance] doubleForKey:kSessionId]];
}

+ (BOOL)updateSessionId {
    double timestampSeconds = [[NSDate date] timeIntervalSince1970];
    double sessionIdSeconds = [[RadarKVStore sharedInstance] doubleForKey:kSessionId];

    RadarFeatureSettings *featureSettings = [RadarSettings featureSettings];
    if (featureSettings.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"flushReplays() from updateSesssionId"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }
    if (timestampSeconds - sessionIdSeconds > 300) {
        [[RadarKVStore sharedInstance] setDouble:timestampSeconds forKey:kSessionId];

        [Radar logOpenedAppConversion];
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"New session | sessionId = %@", [RadarSettings sessionId]]];

        return YES;
    }
    return NO;
}

+ (NSString *)_id {
    return [[RadarKVStore sharedInstance] stringForKey:kId];
}

+ (void)setId:(NSString *)_id {
    [[RadarKVStore sharedInstance] setObject:_id forKey:kId];
}

+ (NSString *)userId {
    return [[RadarKVStore sharedInstance] stringForKey:kUserId];
}

+ (void)setUserId:(NSString *)userId {
    NSString *oldUserId = [[RadarKVStore sharedInstance] stringForKey:kUserId];
    if (oldUserId && ![oldUserId isEqualToString:userId]) {
        [RadarSettings setId:nil];
    }
    [[RadarKVStore sharedInstance] setObject:userId forKey:kUserId];
}

+ (NSString *)__description {
    return [[RadarKVStore sharedInstance] stringForKey:kDescription];
}

+ (void)setDescription:(NSString *)description {
    [[RadarKVStore sharedInstance] setObject:description forKey:kDescription];
}

+ (NSDictionary *)metadata {
    return [[RadarKVStore sharedInstance] dictionaryForKey:kMetadata];
}

+ (void)setMetadata:(NSDictionary *)metadata {
    [[RadarKVStore sharedInstance] setDictionary:metadata forKey:kMetadata];
}

+ (BOOL)anonymousTrackingEnabled {
    return [[RadarKVStore sharedInstance] boolForKey:kAnonymous];
}

+ (void)setAnonymousTrackingEnabled:(BOOL)enabled {
    [[RadarKVStore sharedInstance] setBool:enabled forKey:kAnonymous];
}

+ (BOOL)tracking {
    return [[RadarKVStore sharedInstance] boolForKey:kTracking];
}

+ (void)setTracking:(BOOL)tracking {
    [[RadarKVStore sharedInstance] setBool:tracking forKey:kTracking];
}

+ (RadarTrackingOptions *)trackingOptions {
    NSObject *options = [[RadarKVStore sharedInstance] objectForKey:kTrackingOptions];
    if (options && [options isKindOfClass:[RadarTrackingOptions class]]) {
        return (RadarTrackingOptions *)options;
    } else {
        // default to efficient preset
        return RadarTrackingOptions.presetEfficient;
    }
}

+ (void)setTrackingOptions:(RadarTrackingOptions *)options {
    [[RadarKVStore sharedInstance] setObject:options forKey:kTrackingOptions];
}

+ (void)removeTrackingOptions {
    [[RadarKVStore sharedInstance] removeObjectForKey:kTrackingOptions];
}

+ (RadarTrackingOptions *)previousTrackingOptions {
    NSObject *options = [[RadarKVStore sharedInstance] objectForKey:kPreviousTrackingOptions];
    if (options && [options isKindOfClass:[RadarTrackingOptions class]]) {
        return (RadarTrackingOptions *)options;
    } else {
        return nil;
    }
}

+ (void)setPreviousTrackingOptions:(RadarTrackingOptions *)options {
    [[RadarKVStore sharedInstance] setObject:options forKey:kPreviousTrackingOptions];
}

+ (void)removePreviousTrackingOptions {
    [[RadarKVStore sharedInstance] removeObjectForKey:kPreviousTrackingOptions];
}

+ (RadarTrackingOptions *_Nullable)remoteTrackingOptions {
    NSObject *options = [[RadarKVStore sharedInstance] objectForKey:kRemoteTrackingOptions];
    if (options && [options isKindOfClass:[RadarTrackingOptions class]]) {
        return (RadarTrackingOptions *)options;
    } else {
        return nil;
    }
}

+ (void)setRemoteTrackingOptions:(RadarTrackingOptions *_Nonnull)options {
    [[RadarKVStore sharedInstance] setObject:options forKey:kRemoteTrackingOptions];
}

+ (void)removeRemoteTrackingOptions {
    [[RadarKVStore sharedInstance] removeObjectForKey:kRemoteTrackingOptions];
}

+ (RadarTripOptions *)tripOptions {
    NSObject *options = [[RadarKVStore sharedInstance] objectForKey:kTripOptions];
    if (options && [options isKindOfClass:[RadarTripOptions class]]) {
        return (RadarTripOptions *)options;
    } else {
        return nil;
    }
}

+ (void)setTripOptions:(RadarTripOptions *)options {
    if (options) {
        [[RadarKVStore sharedInstance] setObject:options forKey:kTripOptions];
    } else {
        [[RadarKVStore sharedInstance] removeObjectForKey:kTripOptions];
    }
}

+ (RadarFeatureSettings *)featureSettings {
    NSObject *featureSettings = [[RadarKVStore sharedInstance] objectForKey:kFeatureSettings];
    if (featureSettings && [featureSettings isKindOfClass:[RadarFeatureSettings class]]) {
        return (RadarFeatureSettings *)featureSettings;
    } else {
        return [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO];
    }
}

+ (void)setFeatureSettings:(RadarFeatureSettings *)featureSettings {
    if (featureSettings) {
        //This is added as reading from NSUserdefaults is too slow for this feature flag. To be removed when throttling is done. 
        [[RadarLogBuffer sharedInstance] setPersistentLogFeatureFlag:featureSettings.useLogPersistence];
        [[RadarKVStore sharedInstance] setObject:featureSettings forKey:kFeatureSettings];
    } else {
        [[RadarLogBuffer sharedInstance] setPersistentLogFeatureFlag:NO];
        [[RadarKVStore sharedInstance] removeObjectForKey:kFeatureSettings];
    }
}


+ (RadarLogLevel)logLevel {
    RadarLogLevel logLevel;
    NSInteger logLevelInteger = [[RadarKVStore sharedInstance] integerForKey:kLogLevel];
    if ([RadarSettings userDebug]) {
        logLevel = RadarLogLevelDebug;
    } else {
        if ([[RadarKVStore sharedInstance] keyExists:kLogLevel]) {
            logLevelInteger = [[RadarKVStore sharedInstance] integerForKey:kLogLevel];
            logLevel = (RadarLogLevel)logLevelInteger;
        } else {
            logLevel = RadarLogLevelInfo;
        }
    }
    return logLevel;
}

+ (void)setLogLevel:(RadarLogLevel)level {
    NSInteger logLevelInteger = (int)level;
    [[RadarKVStore sharedInstance] setInteger:logLevelInteger forKey:kLogLevel];
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDs {
    NSObject *beaconUUIDs = [[RadarKVStore sharedInstance] objectForKey:kBeaconUUIDs];
    if (beaconUUIDs && [beaconUUIDs isKindOfClass:[NSArray class]]) {
        return (NSArray<NSString *> *)beaconUUIDs;
    } else {
        return nil;
    }
}

+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [[RadarKVStore sharedInstance] setObject:beaconUUIDs forKey:kBeaconUUIDs];
}

+ (NSString *)host {
    NSString *host = [[RadarKVStore sharedInstance] stringForKey:kHost];
    return host ? host : kDefaultHost;
}

+ (void)updateLastTrackedTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarKVStore sharedInstance] setObject:timeStamp forKey:kLastTrackedTime];
}

+ (NSDate *)lastTrackedTime {
    NSObject *lastTrackedTime = [[RadarKVStore sharedInstance] objectForKey:kLastTrackedTime];
    if (lastTrackedTime && [lastTrackedTime isKindOfClass:[NSDate class]]) {
        return (NSDate *)lastTrackedTime;
    } else {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }
}

+ (NSString *)verifiedHost {
    NSString *verifiedHost = [[RadarKVStore sharedInstance] stringForKey:kVerifiedHost];
    return verifiedHost ? verifiedHost : kDefaultVerifiedHost;
}

+ (BOOL)userDebug {
    if([[RadarKVStore sharedInstance] keyExists:kUserDebug]) {
        return [[RadarKVStore sharedInstance] boolForKey:kUserDebug];
    } else {
        return NO;
    }
}

+ (void)setUserDebug:(BOOL)userDebug {
    [[RadarKVStore sharedInstance] setBool:userDebug forKey:kUserDebug];
}

+ (void)updateLastAppOpenTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarKVStore sharedInstance] setObject:timeStamp forKey:kLastAppOpenTime];
}

+ (NSDate *)lastAppOpenTime {
    NSObject *lastAppOpenTime = [[RadarKVStore sharedInstance] objectForKey:kLastAppOpenTime];
    if (lastAppOpenTime && [lastAppOpenTime isKindOfClass:[NSDate class]]) {
        return (NSDate *)lastAppOpenTime;
    } else {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }
}

@end
