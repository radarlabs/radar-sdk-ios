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
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"publishableKey: %@", [self publishableKey]]];

    NSString *installId = [[NSUserDefaults standardUserDefaults] stringForKey:kInstallId];
    [[RadarKVStore sharedInstance] setObject:installId forKey:kInstallId];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"installId: %@", [self installId]]];

    double sessionId = [[NSUserDefaults standardUserDefaults] doubleForKey:kSessionId];
    [[RadarKVStore sharedInstance] setDouble:sessionId forKey:kSessionId];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"sessionId: %@", [self sessionId]]];

    NSString *_id = [[NSUserDefaults standardUserDefaults] stringForKey:kId];
    [self setId:_id];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"_id: %@", [self _id]]];

    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:kUserId];
    [self setUserId:userId];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"userId: %@", [self userId]]];

    NSString *description = [[NSUserDefaults standardUserDefaults] stringForKey:kDescription];
    [self setDescription:description];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"description: %@", [self __description]]];

    NSObject *metadata = [[NSUserDefaults standardUserDefaults] objectForKey:kMetadata];
    [self setMetadata:(NSDictionary *)metadata];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"metadata: %@", [RadarUtils dictionaryToJson:[self metadata]]]];
    
    BOOL anonymous = [[NSUserDefaults standardUserDefaults] boolForKey:kAnonymous];
    [self setAnonymousTrackingEnabled:anonymous];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"anonymous: %@", [self anonymousTrackingEnabled] ? @"YES" : @"NO"]];

    BOOL tracking = [[NSUserDefaults standardUserDefaults] boolForKey:kTracking];
    [self setTracking:tracking];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"tracking: %@", [self tracking] ? @"YES" : @"NO"]];

    RadarTrackingOptions *trackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kTrackingOptions]];
    [self setTrackingOptions:trackingOptions];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"trackingOptions: %@", [RadarUtils dictionaryToJson:[[self trackingOptions] dictionaryValue]]]];

    RadarTrackingOptions *previousTrackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kPreviousTrackingOptions]];
    [self setPreviousTrackingOptions:previousTrackingOptions];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"previousTrackingOptions: %@", [RadarUtils dictionaryToJson:[[self previousTrackingOptions] dictionaryValue]]]];

    RadarTrackingOptions *remoteTrackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kRemoteTrackingOptions]];
    [self setRemoteTrackingOptions:remoteTrackingOptions];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"remoteTrackingOptions: %@", [RadarUtils dictionaryToJson:[[self remoteTrackingOptions] dictionaryValue]]]];
    
    RadarTripOptions *tripOptions = [RadarTripOptions tripOptionsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kTripOptions]];
    [self setTripOptions:tripOptions];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"tripOptions: %@", [RadarUtils dictionaryToJson:[[self tripOptions] dictionaryValue]]]];
    
    RadarFeatureSettings *featureSettings = [RadarFeatureSettings featureSettingsFromDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kFeatureSettings]];
    [self setFeatureSettings:featureSettings];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"featureSettings: %@", [RadarUtils dictionaryToJson:[[self featureSettings] dictionaryValue]]]];
    
    NSNumber *userDebugNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDebug];
    BOOL userDebug = userDebugNumber ? [userDebugNumber boolValue] : NO;
    [self setUserDebug:userDebug];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"userDebug: %@", [self userDebug] ? @"YES" : @"NO"]];

    RadarLogLevel logLevel;
    if (userDebug) {
        logLevel = RadarLogLevelDebug;
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kLogLevel] == nil) {
        logLevel = RadarLogLevelInfo;
    } else {
        logLevel = (RadarLogLevel)[[NSUserDefaults standardUserDefaults] integerForKey:kLogLevel];
    }
    [self setLogLevel:logLevel];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"logLevel: %ld", (long)[self logLevel]]];

    NSArray<NSString *> *beaconUUIDs = [[NSUserDefaults standardUserDefaults] valueForKey:kBeaconUUIDs];
    [self setBeaconUUIDs:beaconUUIDs];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"beaconUUIDs: %@", [[self beaconUUIDs] componentsJoinedByString:@","]]];
    
    NSString *host = [[NSUserDefaults standardUserDefaults] valueForKey:kHost];
    [[RadarKVStore sharedInstance] setObject:host forKey:kHost];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"host: %@", [self host]]];

    NSString *verifiedHost = [[NSUserDefaults standardUserDefaults] valueForKey:kVerifiedHost];
    [[RadarKVStore sharedInstance] setObject:verifiedHost forKey:kVerifiedHost];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"verifiedHost: %@", [self verifiedHost]]];
    
    NSDate *lastTrackedTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLastTrackedTime];
    [[RadarKVStore sharedInstance] setObject:lastTrackedTime forKey:kLastTrackedTime];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"lastTrackedTime: %@", [self lastTrackedTime]]];

    NSDate *lastAppOpenTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLastAppOpenTime];
    [[RadarKVStore sharedInstance] setObject:lastAppOpenTime forKey:kLastAppOpenTime];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"lastAppOpenTime: %@", [self lastAppOpenTime]]];

    // Log for testing purposes only, to be removed before merging to master.
    NSString *migrationResultString = [migrationResultArray componentsJoinedByString:@", "];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Migration of RadarSettings: %@", migrationResultString]];
}

+ (NSString *)publishableKey {
    return [[RadarKVStore sharedInstance] doubleWriteStringGetter:kPublishableKey];
}

+ (void)setPublishableKey:(NSString *)publishableKey {
    [[RadarKVStore sharedInstance] doubleWriteStringSetter:kPublishableKey value:publishableKey];
}

+ (NSString *)installId {
    NSString *installId = [[RadarKVStore sharedInstance] doubleWriteStringGetter:kInstallId];
    if (!installId) {
        installId = [[NSUUID UUID] UUIDString];
        [[RadarKVStore sharedInstance] doubleWriteStringSetter:kInstallId value:installId];
    }
    return installId;
}

+ (NSString *)sessionId {
   return [NSString stringWithFormat:@"%.f", [[RadarKVStore sharedInstance] doubleWriteDoubleGetter:kSessionId]];
}

+ (BOOL)updateSessionId {
    double timestampSeconds = [[NSDate date] timeIntervalSince1970];
    double sessionIdSeconds = [[RadarKVStore sharedInstance] doubleWriteDoubleGetter:kSessionId];

    RadarFeatureSettings *featureSettings = [RadarSettings featureSettings];
    if (featureSettings.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"flushReplays() from updateSesssionId"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }
    if (timestampSeconds - sessionIdSeconds > 300) {
        [[RadarKVStore sharedInstance] doubleWriteDoubleSetter:kSessionId value:timestampSeconds];
        [Radar logOpenedAppConversion];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"New session | sessionId = %@", [RadarSettings sessionId]]];
        return YES;
    }
    return NO;
}

+ (NSString *)_id {
    return [[RadarKVStore sharedInstance] doubleWriteStringGetter:kId];
}

+ (void)setId:(NSString *)_id {
    [[RadarKVStore sharedInstance] doubleWriteStringSetter:kId value:_id];
}

+ (NSString *)userId {
    return [[RadarKVStore sharedInstance] doubleWriteStringGetter:kUserId];
}

+ (void)setUserId:(NSString *)userId {
    NSString *oldUserId = [self userId];
    if (oldUserId && ![oldUserId isEqualToString:userId]) {
        [RadarSettings setId:nil];
    }
    [[RadarKVStore sharedInstance] doubleWriteStringSetter:kUserId value:userId];
}

+ (NSString *)__description {
    return [[RadarKVStore sharedInstance] doubleWriteStringGetter:kDescription];
}

+ (void)setDescription:(NSString *)description {
    [[RadarKVStore sharedInstance] doubleWriteStringSetter:kDescription value:description];
}

+ (NSDictionary *)metadata {
    NSDictionary *radarKVStoreRes = [[RadarKVStore sharedInstance] dictionaryForKey:kMetadata];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDictionary *userDefaultsRes = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kMetadata];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqual:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqual:radarKVStoreRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarSettings: metadata mismatch."];
    }
    return userDefaultsRes;
}

+ (void)setMetadata:(NSDictionary *)metadata {
    [[RadarKVStore sharedInstance] setDictionary:metadata forKey:kMetadata];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:metadata forKey:kMetadata];
    }
}

+ (BOOL)anonymousTrackingEnabled {
    return [[RadarKVStore sharedInstance] doubleWriteBOOLGetter:kAnonymous];
}

+ (void)setAnonymousTrackingEnabled:(BOOL)enabled {
    [[RadarKVStore sharedInstance] doubleWriteBOOLSetter:kAnonymous value:enabled];
}


+ (BOOL)tracking {
    return [[RadarKVStore sharedInstance] doubleWriteBOOLGetter:kTracking];
}

+ (void)setTracking:(BOOL)tracking {
    [[RadarKVStore sharedInstance] doubleWriteBOOLSetter:kTracking value:tracking];
}

+ (RadarTrackingOptions *)trackingOptions {
    RadarTrackingOptions *options = [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionGetter:kTrackingOptions];

    if (options != nil) {
        return options;
    } else {
        // default to efficient preset
        return RadarTrackingOptions.presetEfficient;
    }
}

+ (void)setTrackingOptions:(RadarTrackingOptions *)options {
  [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionSetter:kTrackingOptions value:options];
}

+ (void)removeTrackingOptions {
    [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionSetter:kTrackingOptions value:nil];
}

+ (RadarTrackingOptions *)previousTrackingOptions {
   return [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionGetter:kPreviousTrackingOptions];
}

+ (void)setPreviousTrackingOptions:(RadarTrackingOptions *)options {
    [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionSetter:kPreviousTrackingOptions value:options];
}

+ (void)removePreviousTrackingOptions {
    [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionSetter:kPreviousTrackingOptions value:nil];
}

+ (RadarTrackingOptions *_Nullable)remoteTrackingOptions {
    return [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionGetter:kRemoteTrackingOptions];
}

+ (void)setRemoteTrackingOptions:(RadarTrackingOptions *_Nonnull)options {
    [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionSetter:kRemoteTrackingOptions value:options];
}

+ (void)removeRemoteTrackingOptions {
    [[RadarKVStore sharedInstance] doubleWriteRadarTrackingOptionSetter:kRemoteTrackingOptions value:nil];
}

+ (RadarTripOptions *)tripOptions {
    RadarTripOptions *radarKVStoreRes = [self tripOptionsWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kTripOptions];
    RadarTripOptions *nsUserDefaultsRes = nil;
    if (optionsDict != nil) {
        nsUserDefaultsRes = [RadarTripOptions tripOptionsFromDictionary:optionsDict];
    }

    if ((nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:radarKVStoreRes]) || (radarKVStoreRes && ![radarKVStoreRes isEqual:nsUserDefaultsRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarSettings: tripOptions mismatch."];
    }
    return nsUserDefaultsRes;   
}

+ (RadarTripOptions *)tripOptionsWithRadarKVStore {
    NSObject *options = [[RadarKVStore sharedInstance] objectForKey:kTripOptions];
    if (options && [options isKindOfClass:[RadarTripOptions class]]) {
        return (RadarTripOptions *)options;
    } else {
        return nil;
    }
}

+ (void)setTripOptions:(RadarTripOptions *)options {
    [self setTripOptionsWithRadarKVStore:options];
    if (![self useRadarKVStore]) {
        if (options) {
            NSDictionary *optionsDict = [options dictionaryValue];
            [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kTripOptions];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTripOptions];
        }
    }
    
}

+ (void)setTripOptionsWithRadarKVStore:(RadarTripOptions *)options {
    if (options) {
        [[RadarKVStore sharedInstance] setObject:options forKey:kTripOptions];
    } else {
        [[RadarKVStore sharedInstance] removeObjectForKey:kTripOptions];
    }
}

+ (BOOL) useRadarKVStore {
    return [[self featureSettings] useRadarKVStore];
}

+ (RadarFeatureSettings *)featureSettings {
    NSObject *featureSettings = [[RadarKVStore sharedInstance] objectForKey:kFeatureSettings];
    if (featureSettings && [featureSettings isKindOfClass:[RadarFeatureSettings class]]) {
        return (RadarFeatureSettings *)featureSettings;
    } else {
        return [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO];
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
    if ([RadarSettings userDebug]) {
        logLevel = RadarLogLevelDebug;
    } else if (![[RadarKVStore sharedInstance] doubleWriteKeyExists:kLogLevel]) {
        logLevel = RadarLogLevelInfo;
    } else {
        logLevel = (RadarLogLevel)[[RadarKVStore sharedInstance] doubleWriteIntegerGetter:kLogLevel];
    }
    return logLevel;
}


+ (void)setLogLevel:(RadarLogLevel)level {
    NSInteger logLevelInteger = (int)level;
    [[RadarKVStore sharedInstance] doubleWriteIntegerSetter:kLogLevel value:logLevelInteger];
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDs {
   return [[RadarKVStore sharedInstance] doubleWriteStringArrayGetter:kBeaconUUIDs];
}

+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [[RadarKVStore sharedInstance] doubleWriteStringArraySetter:kBeaconUUIDs value:beaconUUIDs];
}

+ (NSString *)host {
    NSString *host = [[RadarKVStore sharedInstance] doubleWriteStringGetter:kHost];
    return host ? host : kDefaultHost;
}

+ (NSString *)hostWithRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kHost];
}

+ (void)updateLastTrackedTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarKVStore sharedInstance] doubleWriteDateSetter:kLastTrackedTime value:timeStamp];
}

+ (NSDate *)lastTrackedTime {
    NSDate *lastTrackedTime = [[RadarKVStore sharedInstance] doubleWriteDateGetter:kLastTrackedTime];
    return lastTrackedTime ? lastTrackedTime : [NSDate dateWithTimeIntervalSince1970:0];
}

+ (NSString *)verifiedHost {
    NSString *verifiedHost = [[RadarKVStore sharedInstance] doubleWriteStringGetter:kVerifiedHost];
    return verifiedHost ? verifiedHost : kDefaultVerifiedHost;
}

+ (BOOL)userDebug {
   if (![[RadarKVStore sharedInstance] doubleWriteKeyExists:kUserDebug]) {
        return YES;
    }
    return [[RadarKVStore sharedInstance] doubleWriteBOOLGetter:kUserDebug];
}

+ (void)setUserDebug:(BOOL)userDebug {
    [[RadarKVStore sharedInstance] doubleWriteBOOLSetter:kUserDebug value:userDebug];
}

+ (void)updateLastAppOpenTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarKVStore sharedInstance] doubleWriteDateSetter:kLastAppOpenTime value:timeStamp];
}

+ (NSDate *)lastAppOpenTime {
    NSDate *lastAppOpenTime = [[RadarKVStore sharedInstance] doubleWriteDateGetter:kLastAppOpenTime];
    return lastAppOpenTime ? lastAppOpenTime : [NSDate dateWithTimeIntervalSince1970:0];
}

@end
