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

+ (NSString *)doubleWriteStringGetter:(NSString *)key {
    NSString *radarKVStoreRes = [[RadarKVStore sharedInstance] stringForKey:key];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSString *userDefaultsRes = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqualToString:radarKVStoreRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (void)doubleWriteStringSetter:(NSString *)key value:(NSString *)value {
    [[RadarKVStore sharedInstance] setObject:value forKey:key];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }
}

+ (double)doubleWriteDoubleGetter:(NSString *)key {
    double radarKVStoreRes = [[RadarKVStore sharedInstance] doubleForKey:key];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    double userDefaultsRes = [[NSUserDefaults standardUserDefaults] doubleForKey:key];
    if (radarKVStoreRes != userDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (void)doubleWriteDoubleSetter:(NSString *)key value:(double)value {
    [[RadarKVStore sharedInstance] setDouble:value forKey:key];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setDouble:value forKey:key];
    }
}

+ (BOOL)doubleWriteBOOLGetter:(NSString *)key {
    BOOL radarKVStoreRes = [[RadarKVStore sharedInstance] boolForKey:key];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    BOOL userDefaultsRes = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    if (radarKVStoreRes != userDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (void)doubleWriteBOOLSetter:(NSString *)key value:(BOOL)value {
    [[RadarKVStore sharedInstance] setBool:value forKey:key];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    }
}

+ (NSDate *)doubleWriteDateGetter:(NSString *)key {
    NSObject *radarKVStoreObj = [[RadarKVStore sharedInstance] objectForKey:key];
    NSDate *radarKVStoreRes = nil;
    if (radarKVStoreObj && [radarKVStoreObj isKindOfClass:[NSDate class]]) {
        radarKVStoreRes = (NSDate *)radarKVStoreObj;
    }
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDate *userDefaultsRes = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqual:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqual:radarKVStoreRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (void)doubleWriteDateSetter:(NSString *)key value:(NSDate *)value {
    [[RadarKVStore sharedInstance] setObject:value forKey:key];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }
}

+ (NSArray<NSString *> *_Nullable)doubleWriteStringArrayGetter:(NSString *)key {
    NSObject *radarKVStoreObj = [[RadarKVStore sharedInstance] objectForKey:key];
    NSArray<NSString *> *radarKVStoreRes = nil;
    if (radarKVStoreObj && [radarKVStoreObj isKindOfClass:[NSArray class]]) {
        radarKVStoreRes = (NSArray<NSString *> *)radarKVStoreObj;
    }
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSArray<NSString *> *userDefaultsRes = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqual:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqual:radarKVStoreRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (void)doubleWriteStringArraySetter:(NSString *)key value:(NSArray<NSString *> *)value {
    [[RadarKVStore sharedInstance] setObject:value forKey:key];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }
}

+ (NSInteger)doubleWriteIntegerGetter:(NSString *)key {
    NSInteger radarKVStoreRes = [[RadarKVStore sharedInstance] integerForKey:key];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSInteger userDefaultsRes = [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (radarKVStoreRes != userDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (void)doubleWriteIntegerSetter:(NSString *)key value:(NSInteger)value {
    [[RadarKVStore sharedInstance] setInteger:value forKey:key];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
    }
}

+ (BOOL)doubleWriteKeyExists:(NSString *)key {
    BOOL radarKVStoreRes = [[RadarKVStore sharedInstance] keyExists:key];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    BOOL userDefaultsRes = [[NSUserDefaults standardUserDefaults] objectForKey:key] != nil;
    if (radarKVStoreRes != userDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (NSString *)publishableKey {
    return [self doubleWriteStringGetter:kPublishableKey];
}

+ (void)setPublishableKey:(NSString *)publishableKey {
    [self doubleWriteStringSetter:kPublishableKey value:publishableKey];
}

+ (NSString *)installId {
    NSString *installId = [self doubleWriteStringGetter:kInstallId];
    if (!installId) {
        installId = [[NSUUID UUID] UUIDString];
        [[RadarKVStore sharedInstance] setObject:installId forKey:kInstallId];
        [self doubleWriteStringSetter:kInstallId value:installId];
    }
    return installId;
}

+ (NSString *)sessionId {
   return [NSString stringWithFormat:@"%.f", [self doubleWriteDoubleGetter:kSessionId]];
}

+ (BOOL)updateSessionId {
    double timestampSeconds = [[NSDate date] timeIntervalSince1970];
    double sessionIdSeconds = [self doubleWriteDoubleGetter:kSessionId];

    RadarFeatureSettings *featureSettings = [RadarSettings featureSettings];
    if (featureSettings.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"flushReplays() from updateSesssionId"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }
    if (timestampSeconds - sessionIdSeconds > 300) {
        [self doubleWriteDoubleSetter:kSessionId value:timestampSeconds];

        [Radar logOpenedAppConversion];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"New session | sessionId = %@", [RadarSettings sessionId]]];
        return YES;
    }
    return NO;
}

+ (NSString *)_id {
    return [self doubleWriteStringGetter:kId];
}

+ (void)setId:(NSString *)_id {
    [self doubleWriteStringSetter:kId value:_id];
}

+ (NSString *)userId {
    return [self doubleWriteStringGetter:kUserId];
}

+ (void)setUserId:(NSString *)userId {
    NSString *oldUserId = [self userId];
    if (oldUserId && ![oldUserId isEqualToString:userId]) {
        [RadarSettings setId:nil];
    }
    [self doubleWriteStringSetter:kUserId value:userId];
}

+ (NSString *)__description {
    return [self doubleWriteStringGetter:kDescription];

}

+ (void)setDescription:(NSString *)description {
    [self doubleWriteStringSetter:kDescription value:description];
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
    return [self doubleWriteBOOLGetter:kAnonymous];
}

+ (void)setAnonymousTrackingEnabled:(BOOL)enabled {
    [self doubleWriteBOOLSetter:kAnonymous value:enabled];
}


+ (BOOL)tracking {
    return [self doubleWriteBOOLGetter:kTracking];
}

+ (void)setTracking:(BOOL)tracking {
    [self doubleWriteBOOLSetter:kTracking value:tracking];
}

+ (RadarTrackingOptions *)radarTrackingOptionDecoder:(NSString *)key {
    NSObject *trackingOptions = [[RadarKVStore sharedInstance] objectForKey:key];
    if (trackingOptions && [trackingOptions isKindOfClass:[RadarTrackingOptions class]]) {
        return (RadarTrackingOptions *)trackingOptions;
    } else {
        return nil;
    }
}

+ (RadarTrackingOptions *)doubleWriteRadarTrackingOptionGetter:(NSString *)key {
    RadarTrackingOptions *radarKVStoreRes = [self radarTrackingOptionDecoder:key];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    RadarTrackingOptions *userDefaultsRes = nil;
    if (optionsDict != nil) {
        userDefaultsRes = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    }
    if ((userDefaultsRes && ![userDefaultsRes isEqual:radarKVStoreRes]) || (radarKVStoreRes && ![radarKVStoreRes isEqual:userDefaultsRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return userDefaultsRes;
}

+ (void)doubleWriteRadarTrackingOptionSetter:(NSString *)key value:(RadarTrackingOptions *)value {
    [[RadarKVStore sharedInstance] setObject:value forKey:key];
    if (![self useRadarKVStore]) {
        if (!value) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            return;
        }
        NSDictionary *optionsDict = [value dictionaryValue];
        [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:key];
    }
}

+ (RadarTrackingOptions *)trackingOptions {
    RadarTrackingOptions *trackingOptions = [self doubleWriteRadarTrackingOptionGetter:kTrackingOptions];
    if (trackingOptions != nil) {
        return trackingOptions;
    } else {
        return RadarTrackingOptions.presetEfficient;
    } 
}

+ (void)setTrackingOptions:(RadarTrackingOptions *)options {
    [self doubleWriteRadarTrackingOptionSetter:kTrackingOptions value:options];
}

+ (void)removeTrackingOptions {
    [self doubleWriteRadarTrackingOptionSetter:kTrackingOptions value:nil];
}

+ (RadarTrackingOptions *)previousTrackingOptions {
   return [self doubleWriteRadarTrackingOptionGetter:kPreviousTrackingOptions];
}

+ (void)setPreviousTrackingOptions:(RadarTrackingOptions *)options {
    [self doubleWriteRadarTrackingOptionSetter:kPreviousTrackingOptions value:options];
}

+ (void)removePreviousTrackingOptions {
    [self doubleWriteRadarTrackingOptionSetter:kPreviousTrackingOptions value:nil];
}

+ (RadarTrackingOptions *_Nullable)remoteTrackingOptions {
   return [self doubleWriteRadarTrackingOptionGetter:kRemoteTrackingOptions];
}

+ (void)setRemoteTrackingOptions:(RadarTrackingOptions *_Nonnull)options {
    [self doubleWriteRadarTrackingOptionSetter:kRemoteTrackingOptions value:options];
}

+ (void)removeRemoteTrackingOptions {
    [self doubleWriteRadarTrackingOptionSetter:kRemoteTrackingOptions value:nil];
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
    } else if (![self doubleWriteKeyExists:kLogLevel]) {
        logLevel = RadarLogLevelInfo;
    } else {
        logLevel = (RadarLogLevel)[self doubleWriteIntegerGetter:kLogLevel];
    }
    return logLevel;
}


+ (void)setLogLevel:(RadarLogLevel)level {
    NSInteger logLevelInteger = (int)level;
    [self doubleWriteIntegerSetter:kLogLevel value:logLevelInteger];
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDs {
   return [self doubleWriteStringArrayGetter:kBeaconUUIDs];
}

+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [self doubleWriteStringArraySetter:kBeaconUUIDs value:beaconUUIDs];
}

+ (NSString *)host {
    NSString *host = [self doubleWriteStringGetter:kHost];
    return host ? host : kDefaultHost;
}

+ (NSString *)hostWithRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kHost];
}

+ (void)updateLastTrackedTime {
    NSDate *timeStamp = [NSDate date];
    [self doubleWriteDateSetter:kLastTrackedTime value:timeStamp];
}

+ (NSDate *)lastTrackedTime {
    NSDate *lastTrackedTime = [self doubleWriteDateGetter:kLastTrackedTime];
    return lastTrackedTime ? lastTrackedTime : [NSDate dateWithTimeIntervalSince1970:0];
}

+ (NSString *)verifiedHost {
    NSString *verifiedHost = [self doubleWriteStringGetter:kVerifiedHost];
    return verifiedHost ? verifiedHost : kDefaultVerifiedHost;
}

+ (BOOL)userDebug {
   if (![self doubleWriteKeyExists:kUserDebug]) {
        return YES;
    }
    return [self doubleWriteBOOLGetter:kUserDebug];
}

+ (void)setUserDebug:(BOOL)userDebug {
    [self doubleWriteBOOLSetter:kUserDebug value:userDebug];
}

+ (void)updateLastAppOpenTime {
    NSDate *timeStamp = [NSDate date];
    [self doubleWriteDateSetter:kLastAppOpenTime value:timeStamp];
}

+ (NSDate *)lastAppOpenTime {
    NSDate *lastAppOpenTime = [self doubleWriteDateGetter:kLastAppOpenTime];
    return lastAppOpenTime ? lastAppOpenTime : [NSDate dateWithTimeIntervalSince1970:0];
}

@end
