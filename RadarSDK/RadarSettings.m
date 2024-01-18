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
    NSString *radarKVStoreRes = [self publishableKeyUsingRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSString *userDefaultsRes = [[NSUserDefaults standardUserDefaults] stringForKey:kPublishableKey];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqualToString:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: publishableKey mismatch."];
    }

    return userDefaultsRes;
}

+ (NSString *)publishableKeyUsingRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kPublishableKey];
}

+ (void)setPublishableKey:(NSString *)publishableKey {
    [self setPublishableKeyUsingRadarKVStore:publishableKey];
    if (![self useRadarKVStore]) {
        [[RadarKVStore sharedInstance] setObject:publishableKey forKey:kPublishableKey];
    }
}

+ (void)setPublishableKeyUsingRadarKVStore:(NSString *)publishableKey {
    [[RadarKVStore sharedInstance] setObject:publishableKey forKey:kPublishableKey];
}

+ (NSString *)installId {
    NSString *radarKVStoreRes = [self installIdUsingRadarKVStore];
    NSString *installId = radarKVStoreRes;
    if (![self useRadarKVStore]) {
         NSString *nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] stringForKey:kInstallId];
        if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:nsUserDefaultsRes]) || (nsUserDefaultsRes && ![nsUserDefaultsRes isEqualToString:radarKVStoreRes])) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: installId mismatch."];
        }
        installId = nsUserDefaultsRes;
    }
   
    if (!installId) {
        installId = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:installId forKey:kInstallId];
    }
    return installId;
}

+ (NSString *)installIdUsingRadarKVStore {
   return [[RadarKVStore sharedInstance] stringForKey:kInstallId];
}

+ (NSString *)sessionId {
    NSString *radarKVStoreRes = [self sessionIdWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSString *userDefaultsRes = [NSString stringWithFormat:@"%.f", [[NSUserDefaults standardUserDefaults] doubleForKey:kSessionId]];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqualToString:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: sessionId mismatch."];
    }
    return userDefaultsRes;
}

+ (NSString *)sessionIdWithRadarKVStore {
    return [NSString stringWithFormat:@"%.f", [[RadarKVStore sharedInstance] doubleForKey:kSessionId]];
}

+ (BOOL)updateSessionId {
    double timestampSeconds = [[NSDate date] timeIntervalSince1970];
    double sessionIdSeconds = [[RadarKVStore sharedInstance] doubleForKey:kSessionId];
    if (![self useRadarKVStore]) {
        double nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] doubleForKey:kSessionId];
        if (sessionIdSeconds != nsUserDefaultsRes) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: sessionId mismatch."];
        }
        sessionIdSeconds = nsUserDefaultsRes;
    }

    RadarFeatureSettings *featureSettings = [RadarSettings featureSettings];
    if (featureSettings.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"flushReplays() from updateSesssionId"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }
    if (timestampSeconds - sessionIdSeconds > 300) {
        [[RadarKVStore sharedInstance] setDouble:timestampSeconds forKey:kSessionId];
        if (![self useRadarKVStore]) {
            [[NSUserDefaults standardUserDefaults] setDouble:timestampSeconds forKey:kSessionId];
        }

        [Radar logOpenedAppConversion];
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"New session | sessionId = %@", [RadarSettings sessionId]]];

        return YES;
    }
    return NO;
}

+ (NSString *)_id {
    NSString *radarKVStoreRes = [self _idWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSString *userDefaultsRes = [[NSUserDefaults standardUserDefaults] stringForKey:kId];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqualToString:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: _id mismatch."];
    }
    return userDefaultsRes;
}

+ (NSString *)_idWithRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kId];
}

+ (void)setId:(NSString *)_id {
    [self setIdWithRadarKVStore:_id];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:_id forKey:kId];
    }
}

+ (void)setIdWithRadarKVStore:(NSString *)_id {
    [[RadarKVStore sharedInstance] setObject:_id forKey:kId];
}

+ (NSString *)userId {
    NSString *radarKVStoreRes = [self userIdWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSString *userDefaultsRes = [[NSUserDefaults standardUserDefaults] stringForKey:kUserId];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqualToString:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: userId mismatch."];
    }
    return userDefaultsRes;
}

+ (NSString *)userIdWithRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kUserId];
}

+ (void)setUserId:(NSString *)userId {
    NSString *oldUserId = [[RadarKVStore sharedInstance] stringForKey:kUserId];
    if (![self useRadarKVStore]) {
        oldUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kUserId];
    }
    if (oldUserId && ![oldUserId isEqualToString:userId]) {
        [RadarSettings setId:nil];
    }
    [[RadarKVStore sharedInstance] setObject:userId forKey:kUserId];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:userId forKey:kUserId];
    }
}

+ (NSString *)__description {
    NSString *radarKVStoreRes = [self __descriptionWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSString *userDefaultsRes = [[NSUserDefaults standardUserDefaults] stringForKey:kDescription];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqualToString:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: description mismatch."];
    }
    return userDefaultsRes;
}

+ (NSString *)__descriptionWithRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kDescription];
}

+ (void)setDescription:(NSString *)description {
    [self setDescriptionWithRadarKVStore:description];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:description forKey:kDescription];
    }
}

+ (void)setDescriptionWithRadarKVStore:(NSString *)description {
    [[RadarKVStore sharedInstance] setObject:description forKey:kDescription];
}

+ (NSDictionary *)metadata {
    NSDictionary *radarKVStoreRes = [self metadataWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDictionary *userDefaultsRes = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kMetadata];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToDictionary:userDefaultsRes]) || (userDefaultsRes && ![userDefaultsRes isEqualToDictionary:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: metadata mismatch."];
    }
    return userDefaultsRes;
}

+ (NSDictionary *)metadataWithRadarKVStore {
    return [[RadarKVStore sharedInstance] dictionaryForKey:kMetadata];
}

+ (void)setMetadata:(NSDictionary *)metadata {
    [self setMetadataWithRadarKVStore:metadata];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:metadata forKey:kMetadata];
    }
}

+ (void)setMetadataWithRadarKVStore:(NSDictionary *)metadata {
    [[RadarKVStore sharedInstance] setDictionary:metadata forKey:kMetadata];
}

+ (BOOL)anonymousTrackingEnabled {
    BOOL radarKVStoreRes = [self anonymousTrackingEnabledWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    BOOL userDefaultsRes = [[NSUserDefaults standardUserDefaults] boolForKey:kAnonymous];
    if (radarKVStoreRes != userDefaultsRes) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: anonymous mismatch."];
    }
    return userDefaultsRes;
}

+ (BOOL)anonymousTrackingEnabledWithRadarKVStore {
    return [[RadarKVStore sharedInstance] boolForKey:kAnonymous];
}

+ (void)setAnonymousTrackingEnabled:(BOOL)enabled {
    [self setAnonymousTrackingEnabledWithRadarKVStore:enabled];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kAnonymous];
    }
}

+ (void)setAnonymousTrackingEnabledWithRadarKVStore:(BOOL)enabled {
    [[RadarKVStore sharedInstance] setBool:enabled forKey:kAnonymous];
}

+ (BOOL)tracking {
    BOOL radarKVStoreRes = [self trackingWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    BOOL userDefaultsRes = [[NSUserDefaults standardUserDefaults] boolForKey:kTracking];
    if (radarKVStoreRes != userDefaultsRes) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: tracking mismatch."];
    }
    return userDefaultsRes;
}

+ (BOOL)trackingWithRadarKVStore {
    return [[RadarKVStore sharedInstance] boolForKey:kTracking];
}

+ (void)setTracking:(BOOL)tracking {
    [self setTrackingWithRadarKVStore:tracking];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setBool:tracking forKey:kTracking];
    }
}

+ (void)setTrackingWithRadarKVStore:(BOOL)tracking {
    [[RadarKVStore sharedInstance] setBool:tracking forKey:kTracking];
}

+ (RadarTrackingOptions *)radarTrackingOptionDecoder:(NSString *)key {
    NSObject *trackingOptions = [[RadarKVStore sharedInstance] objectForKey:key];
    if (trackingOptions && [trackingOptions isKindOfClass:[RadarTrackingOptions class]]) {
        return (RadarTrackingOptions *)trackingOptions;
    } else {
        return nil;
    }
}

+ (RadarTrackingOptions *)trackingOptions {
    RadarTrackingOptions *radarKVStoreRes = [self trackingOptionsWithRadarKVStore];
    if ([self useRadarKVStore]) {
        if (radarKVStoreRes) {
            return radarKVStoreRes;
        } else {
            return RadarTrackingOptions.presetEfficient;
        }
    }
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kTrackingOptions];

    if (optionsDict != nil) {
        RadarTrackingOptions *options = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
        if ((options && ![options isEqual:radarKVStoreRes]) || (radarKVStoreRes && ![radarKVStoreRes isEqual:options])) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: trackingOptions mismatch."];
        }
        return [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
        
    } else {
        if (radarKVStoreRes) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: trackingOptions mismatch."];
        }
        // default to efficient preset
        return RadarTrackingOptions.presetEfficient;
    }
}

+ (RadarTrackingOptions *)trackingOptionsWithRadarKVStore {
    return [self radarTrackingOptionDecoder:kTrackingOptions];
}

+ (void)setTrackingOptions:(RadarTrackingOptions *)options {
    [self setTrackingOptionsWithRadarKVStore:options];
    if (![self useRadarKVStore]) {
        NSDictionary *optionsDict = [options dictionaryValue];
        [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kTrackingOptions];
    }
}

+ (void)setTrackingOptionsWithRadarKVStore:(RadarTrackingOptions *)options {
    [[RadarKVStore sharedInstance] setObject:options forKey:kTrackingOptions];
}

+ (void)removeTrackingOptions {
    [[RadarKVStore sharedInstance] removeObjectForKey:kTrackingOptions];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTrackingOptions];
    }
}

+ (RadarTrackingOptions *)previousTrackingOptions {
    RadarTrackingOptions *radarKVStoreRes = [self previousTrackingOptionsWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }

    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kPreviousTrackingOptions];
    RadarTrackingOptions *nsUserDefaultsRes = nil; 
    if (optionsDict != nil) {
        nsUserDefaultsRes = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    }  
    if ((nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:radarKVStoreRes]) || (radarKVStoreRes && ![radarKVStoreRes isEqual:nsUserDefaultsRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: previousTrackingOptions mismatch."];
    }
    return nsUserDefaultsRes;
}

+ (RadarTrackingOptions *)previousTrackingOptionsWithRadarKVStore {
    return [self radarTrackingOptionDecoder:kPreviousTrackingOptions];
}

+ (void)setPreviousTrackingOptions:(RadarTrackingOptions *)options {
    [self setPreviousTrackingOptionsWithRadarKVStore:options];
    if (![self useRadarKVStore]) {
        NSDictionary *optionsDict = [options dictionaryValue];
        [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kPreviousTrackingOptions];
    }
}

+ (void)setPreviousTrackingOptionsWithRadarKVStore:(RadarTrackingOptions *)options {
    [[RadarKVStore sharedInstance] setObject:options forKey:kPreviousTrackingOptions];
}

+ (void)removePreviousTrackingOptions {
    [[RadarKVStore sharedInstance] removeObjectForKey:kPreviousTrackingOptions];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPreviousTrackingOptions];
    }
}

+ (RadarTrackingOptions *_Nullable)remoteTrackingOptions {
    RadarTrackingOptions *radarKVStoreRes = [self remoteTrackingOptionsWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kRemoteTrackingOptions];
    RadarTrackingOptions *nsUserDefaultsRes = nil;
    if (optionsDict != nil) {
        nsUserDefaultsRes = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    }
    if ((nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:radarKVStoreRes]) || (radarKVStoreRes && ![radarKVStoreRes isEqual:nsUserDefaultsRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: remoteTrackingOptions mismatch."];
    }
    return nsUserDefaultsRes;
}

+ (RadarTrackingOptions *)remoteTrackingOptionsWithRadarKVStore {
    return [self radarTrackingOptionDecoder:kRemoteTrackingOptions];
}

+ (void)setRemoteTrackingOptions:(RadarTrackingOptions *_Nonnull)options {
    [self setRemoteTrackingOptionsWithRadarKVStore:options];
    if (![self useRadarKVStore]) {
        NSDictionary *optionsDict = [options dictionaryValue];
        [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:kRemoteTrackingOptions];
    }
}

+ (void)setRemoteTrackingOptionsWithRadarKVStore:(RadarTrackingOptions *_Nonnull)options {
    [[RadarKVStore sharedInstance] setObject:options forKey:kRemoteTrackingOptions];
}

+ (void)removeRemoteTrackingOptions {
    [[RadarKVStore sharedInstance] removeObjectForKey:kRemoteTrackingOptions];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRemoteTrackingOptions];
    }
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
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: tripOptions mismatch."];
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
    RadarLogLevel radarKVStoreRes = [self logLevelWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    RadarLogLevel logLevel;
    if ([RadarSettings userDebug]) {
        logLevel = RadarLogLevelDebug;
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kLogLevel] == nil) {
        logLevel = RadarLogLevelInfo;
    } else {
        logLevel = (RadarLogLevel)[[NSUserDefaults standardUserDefaults] integerForKey:kLogLevel];
    }
    if (radarKVStoreRes != logLevel) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: logLevel mismatch."];
    }
    return logLevel;
}

+ (RadarLogLevel)logLevelWithRadarKVStore {
    RadarLogLevel logLevel;
    if ([RadarSettings userDebug]) {
        logLevel = RadarLogLevelDebug;
    } else {
        if ([[RadarKVStore sharedInstance] keyExists:kLogLevel]) {
            logLevel = (RadarLogLevel)[[RadarKVStore sharedInstance] integerForKey:kLogLevel];
        } else {
            logLevel = RadarLogLevelInfo;
        }
    }
    return logLevel;
}

+ (void)setLogLevel:(RadarLogLevel)level {
    [self setLogLevelWithRadarKVStore:level];
    if (![self useRadarKVStore]) {
        NSInteger logLevelInteger = (int)level;
        [[NSUserDefaults standardUserDefaults] setInteger:logLevelInteger forKey:kLogLevel];
    }
}

+ (void)setLogLevelWithRadarKVStore:(RadarLogLevel)level {
    NSInteger logLevelInteger = (int)level;
    [[RadarKVStore sharedInstance] setInteger:logLevelInteger forKey:kLogLevel];
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDs {
    NSArray<NSString *> *radarKVStoreRes = [self beaconUUIDsWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSArray<NSString *> *beaconUUIDs = [[NSUserDefaults standardUserDefaults] valueForKey:kBeaconUUIDs];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToArray:beaconUUIDs]) || (beaconUUIDs && ![beaconUUIDs isEqualToArray:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: beaconUUIDs mismatch."];
    }
    return beaconUUIDs;
}

+ (NSArray<NSString *> *_Nullable)beaconUUIDsWithRadarKVStore {
    NSObject *beaconUUIDs = [[RadarKVStore sharedInstance] objectForKey:kBeaconUUIDs];
    if (beaconUUIDs && [beaconUUIDs isKindOfClass:[NSArray class]]) {
        return (NSArray<NSString *> *)beaconUUIDs;
    } else {
        return nil;
    }
}

+ (void)setBeaconUUIDs:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [self setBeaconUUIDsWithRadarKVStore:beaconUUIDs];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setValue:beaconUUIDs forKey:kBeaconUUIDs];
    }
}

+ (void)setBeaconUUIDsWithRadarKVStore:(NSArray<NSString *> *_Nullable)beaconUUIDs {
    [[RadarKVStore sharedInstance] setObject:beaconUUIDs forKey:kBeaconUUIDs];
}

+ (NSString *)host {
    NSString *radarKVStoreRes = [self hostWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes ? radarKVStoreRes : kDefaultHost;
    }
    NSString *host = [[RadarKVStore sharedInstance] stringForKey:kHost];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:host]) || (host && ![host isEqualToString:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: host mismatch."];
    }
    return host ? host : kDefaultHost;
}

+ (NSString *)hostWithRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kHost];
}

+ (void)updateLastTrackedTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarKVStore sharedInstance] setObject:timeStamp forKey:kLastTrackedTime];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:timeStamp forKey:kLastTrackedTime];
    }
}

+ (NSDate *)lastTrackedTime {
    NSObject *lastTrackedTime = [[RadarKVStore sharedInstance] objectForKey:kLastTrackedTime];
    NSDate *lastTrackedTimeDate = nil;
    if (lastTrackedTime && [lastTrackedTime isKindOfClass:[NSDate class]]) {
        lastTrackedTimeDate = (NSDate *)lastTrackedTime;
    }
    if (![self useRadarKVStore]) {
        NSDate *nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] objectForKey:kLastTrackedTime];
        if ((lastTrackedTimeDate && ![lastTrackedTimeDate isEqual:nsUserDefaultsRes]) || (nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:lastTrackedTimeDate])) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: lastTrackedTime mismatch."];
        }
        lastTrackedTimeDate = nsUserDefaultsRes;
    }   
    return lastTrackedTimeDate ? lastTrackedTimeDate : [NSDate dateWithTimeIntervalSince1970:0];
}

+ (NSString *)verifiedHost {
    NSString *radarKVStoreRes = [self verifiedHostWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes ? radarKVStoreRes : kDefaultVerifiedHost;
    }
    NSString *verifiedHost = [[RadarKVStore sharedInstance] stringForKey:kVerifiedHost];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:verifiedHost]) || (verifiedHost && ![verifiedHost isEqualToString:radarKVStoreRes])) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: verifiedHost mismatch."];
    }
    return verifiedHost ? verifiedHost : kDefaultVerifiedHost;
}

+ (NSString *)verifiedHostWithRadarKVStore {
    return [[RadarKVStore sharedInstance] stringForKey:kVerifiedHost];
}

+ (BOOL)userDebug {
    BOOL radarKVStoreRes = [self userDebugWithRadarKVStore];
    if ([self useRadarKVStore]) {
        return radarKVStoreRes;
    }
    BOOL userDefaultsRes = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDebug];
    if (radarKVStoreRes != userDefaultsRes) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: userDebug mismatch."];
    }
    return userDefaultsRes;
}

+ (BOOL)userDebugWithRadarKVStore {
    return [[RadarKVStore sharedInstance] boolForKey:kUserDebug];
}

+ (void)setUserDebug:(BOOL)userDebug {
    [self setUserDebugWithRadarKVStore:userDebug];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setBool:userDebug forKey:kUserDebug];
    }
}

+ (void)setUserDebugWithRadarKVStore:(BOOL)userDebug {
    [[RadarKVStore sharedInstance] setBool:userDebug forKey:kUserDebug];
}

+ (void)updateLastAppOpenTime {
    NSDate *timeStamp = [NSDate date];
    [[RadarKVStore sharedInstance] setObject:timeStamp forKey:kLastAppOpenTime];
    if (![self useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:timeStamp forKey:kLastAppOpenTime];
    }
}

+ (NSDate *)lastAppOpenTime {
    NSObject *lastAppOpenTime = [[RadarKVStore sharedInstance] objectForKey:kLastAppOpenTime];
    NSDate *lastAppOpenTimeDate = nil;
    if (lastAppOpenTime && [lastAppOpenTime isKindOfClass:[NSDate class]]) {
        lastAppOpenTimeDate = (NSDate *)lastAppOpenTime;
    }
    if (![self useRadarKVStore]) {
        NSDate *nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] objectForKey:kLastAppOpenTime];
        if ((lastAppOpenTimeDate && ![lastAppOpenTimeDate isEqual:nsUserDefaultsRes]) || (nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:lastAppOpenTimeDate])) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"RadarSettings: lastAppOpenTime mismatch."];
        }
        lastAppOpenTimeDate = nsUserDefaultsRes;
    }

    return lastAppOpenTimeDate ? lastAppOpenTimeDate : [NSDate dateWithTimeIntervalSince1970:0];
}

@end
