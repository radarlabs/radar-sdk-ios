//
//  RadarKVStore.m
//  RadarSDK
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarKVStore.h"
#import "RadarFileStorage.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarLogBuffer.h"
#import "CLLocation+Radar.h"
#import "RadarUtils.h"
#import "RadarTrackingOptions.h"
#import "RadarTripOptions.h"

@implementation RadarKVStore 


static NSString *const kCompletedMigration = @"radar-completed-KVStore-migration";
static NSString *const kDirName = @"radar-KVStore";


+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        self.settingsFileDir = [documentsDirectory stringByAppendingPathComponent:kDirName];
        self.fileHandler = [[RadarFileStorage alloc] init];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.settingsFileDir isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.settingsFileDir withIntermediateDirectories:YES attributes:nil error:nil];
            self.radarKVStoreMigrationComplete = NO;
        } else {
            self.radarKVStoreMigrationComplete = [self boolForKey:kCompletedMigration];
        }
    }
    return self;
}

- (NSString *)getSettingFilePath:(NSString *)key {
    return [self.settingsFileDir stringByAppendingPathComponent:key];
}

- (void)setRadarKVStoreMigrationComplete:(BOOL)migrationCompleteFlag {
    _radarKVStoreMigrationComplete = migrationCompleteFlag;
    [self setBool:migrationCompleteFlag forKey:kCompletedMigration];
}

- (BOOL)boolForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return NO;
    }
    BOOL value;
    [data getBytes:&value length:sizeof(value)];
    return value;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self.fileHandler writeData:[NSData dataWithBytes:&value length:sizeof(value)] toFileAtPath:[self getSettingFilePath:key]];
}

- (NSString *_Nullable)stringForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return nil;
    }
    NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // handle case where string was encoded as NSObject
    if (!value) {
        value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return value;
}

- (void)setString:(NSString *_Nullable)value forKey:(NSString *)key {
    if (!value) {
        [self.fileHandler deleteFileAtPath:[self getSettingFilePath:key]];
        return;
    }
    [self.fileHandler writeData:[value dataUsingEncoding:NSUTF8StringEncoding] toFileAtPath:[self getSettingFilePath:key]];
}

- (NSDictionary *_Nullable)dictionaryForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return nil;
    }
    NSError *error;
    NSDictionary *value = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        return nil;
    }
    return value;
}

- (void)setDictionary:(NSDictionary *_Nullable)value forKey:(NSString *)key {
    if (!value) {
        [self.fileHandler deleteFileAtPath:[self getSettingFilePath:key]];
        return;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
    if (error) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"Failed to serialize dictionary: %@", error.localizedDescription]];
    }
    [self.fileHandler writeData:jsonData toFileAtPath:[self getSettingFilePath:key]];
}

- (double)doubleForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return 0;
    }
    double value;
    [data getBytes:&value length:sizeof(value)];
    return value;
}

- (void)setDouble:(double)value forKey:(NSString *)key {
    [self.fileHandler writeData:[NSData dataWithBytes:&value length:sizeof(value)] toFileAtPath:[self getSettingFilePath:key]];
}

- (NSObject *_Nullable)objectForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return nil;
    }
    NSObject *value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return value;
}

- (void)setObject:(NSObject *_Nullable)value forKey:(NSString *)key {
    if (!value) {
        [self.fileHandler deleteFileAtPath:[self getSettingFilePath:key]];
        return;
    }
    [self.fileHandler writeData:[NSKeyedArchiver archivedDataWithRootObject:value] toFileAtPath:[self getSettingFilePath:key]];
}

- (void)removeObjectForKey:(NSString *)key {
    [self.fileHandler deleteFileAtPath:[self getSettingFilePath:key]];
}

- (NSInteger)integerForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return 0;
    }
    NSInteger value;
    [data getBytes:&value length:sizeof(value)];
    return value;
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    [self.fileHandler writeData:[NSData dataWithBytes:&value length:sizeof(value)] toFileAtPath:[self getSettingFilePath:key]];
}

- (void)removeAllObjects {
    NSArray<NSString *> *allSettings = [self.fileHandler sortedFilesInDirectory:self.settingsFileDir];
    for (NSString *setting in allSettings) {
        [self.fileHandler deleteFileAtPath:[self getSettingFilePath:setting]];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:self.settingsFileDir withIntermediateDirectories:YES attributes:nil error:nil];
}

- (BOOL)keyExists:(NSString *)key {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self getSettingFilePath:key]];
}

- (NSString *)doubleWriteStringGetter:(NSString *)key {
    NSString *radarKVStoreRes = [self stringForKey:key];
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSString *nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqualToString:nsUserDefaultsRes]) || (nsUserDefaultsRes && ![nsUserDefaultsRes isEqualToString:radarKVStoreRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}

- (void)doubleWriteStringSetter:(NSString *)key value:(NSString *)value {
    [self setString:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }
}

- (double)doubleWriteDoubleGetter:(NSString *)key {
    double radarKVStoreRes = [self doubleForKey:key];
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    double nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] doubleForKey:key];
    if (radarKVStoreRes != nsUserDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}

- (void)doubleWriteDoubleSetter:(NSString *)key value:(double)value {
    [self setDouble:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setDouble:value forKey:key];
    }
}

- (BOOL)doubleWriteBOOLGetter:(NSString *)key {
    BOOL radarKVStoreRes = [self boolForKey:key];
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    BOOL nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    if (radarKVStoreRes != nsUserDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}

- (void)doubleWriteBOOLSetter:(NSString *)key value:(BOOL)value {
    [self setBool:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    }
}

- (NSDate *)doubleWriteDateGetter:(NSString *)key {
    NSObject *radarKVStoreObj = [self objectForKey:key];
    NSDate *radarKVStoreRes = nil;
    if (radarKVStoreObj && [radarKVStoreObj isKindOfClass:[NSDate class]]) {
        radarKVStoreRes = (NSDate *)radarKVStoreObj;
    }
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDate *nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqual:nsUserDefaultsRes]) || (nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:radarKVStoreRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}

- (void)doubleWriteDateSetter:(NSString *)key value:(NSDate *)value {
    [self setObject:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }
}

- (NSArray<NSString *> *_Nullable)doubleWriteStringArrayGetter:(NSString *)key {
    NSObject *radarKVStoreObj = [self objectForKey:key];
    NSArray<NSString *> *radarKVStoreRes = nil;
    if (radarKVStoreObj && [radarKVStoreObj isKindOfClass:[NSArray class]]) {
        radarKVStoreRes = (NSArray<NSString *> *)radarKVStoreObj;
    }
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSArray<NSString *> *nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if ((radarKVStoreRes && ![radarKVStoreRes isEqual:nsUserDefaultsRes]) || (nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:radarKVStoreRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}

- (void)doubleWriteStringArraySetter:(NSString *)key value:(NSArray<NSString *> *)value {
    [self setObject:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }
}

- (NSInteger)doubleWriteIntegerGetter:(NSString *)key {
    NSInteger radarKVStoreRes = [self integerForKey:key];
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSInteger nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (radarKVStoreRes != nsUserDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}

- (void)doubleWriteIntegerSetter:(NSString *)key value:(NSInteger)value {
    [self setInteger:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
    }
}

- (BOOL)doubleWriteKeyExists:(NSString *)key {
    BOOL radarKVStoreRes = [self keyExists:key];
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    BOOL nsUserDefaultsRes = [[NSUserDefaults standardUserDefaults] objectForKey:key] != nil;
    if (radarKVStoreRes != nsUserDefaultsRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}


- (CLLocation *)doubleWriteCLLocationGetter:(NSString *)key {
    NSObject *radarKVStoreObj = [self objectForKey:key];
    CLLocation *radarKVStoreRes = nil;
    if (radarKVStoreObj && [radarKVStoreObj isKindOfClass:[CLLocation class]]) {
        radarKVStoreRes = (CLLocation *)radarKVStoreObj;
        if (!radarKVStoreRes.isValid) {
            radarKVStoreRes = nil;
        }
    }

    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }

    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    CLLocation *nsUserDefaultsRes = [RadarUtils locationForDictionary:dict];
    if (!nsUserDefaultsRes.isValid) {
        nsUserDefaultsRes = nil;
    }

    if (![RadarUtils compareCLLocation:radarKVStoreRes with:nsUserDefaultsRes]) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Discrepencey with NSUserDefault %@ mismatch.", key]];
    }
    return nsUserDefaultsRes; 
}

- (void)doubleWriteCLLocationSetter:(NSString *)key value:(CLLocation *_Nullable)value {
    [self setObject:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:value] forKey:key];
    }
}

- (RadarTrackingOptions *)radarTrackingOptionDecoder:(NSString *)key {
    NSObject *trackingOptions = [self objectForKey:key];
    if (trackingOptions && [trackingOptions isKindOfClass:[RadarTrackingOptions class]]) {
        return (RadarTrackingOptions *)trackingOptions;
    } else {
        return nil;
    }
}

- (RadarTrackingOptions *)doubleWriteRadarTrackingOptionGetter:(NSString *)key {
    RadarTrackingOptions *radarKVStoreRes = [self radarTrackingOptionDecoder:key];
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    RadarTrackingOptions *nsUserDefaultsRes = nil;
    if (optionsDict != nil) {
        nsUserDefaultsRes = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    }
    if ((nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:radarKVStoreRes]) || (radarKVStoreRes && ![radarKVStoreRes isEqual:nsUserDefaultsRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"RadarSettings: %@ mismatch.", key]];
    }
    return nsUserDefaultsRes;
}

- (void)doubleWriteRadarTrackingOptionSetter:(NSString *)key value:(RadarTrackingOptions *_Nullable)value {
    [self setObject:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        if (!value) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            return;
        }
        NSDictionary *optionsDict = [value dictionaryValue];
        [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:key];
    }
}

- (RadarTripOptions *)doubleWriteRadarTripOptionsGetter:(NSString *)key {
    NSObject *options = [[RadarKVStore sharedInstance] objectForKey:key];
    RadarTripOptions *radarKVStoreRes = nil;
    if (options && [options isKindOfClass:[RadarTripOptions class]]) {
        radarKVStoreRes = (RadarTripOptions *)options;
    } 
    
    if ([RadarSettings useRadarKVStore]) {
        return radarKVStoreRes;
    }
    NSDictionary *optionsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    RadarTripOptions *nsUserDefaultsRes = nil;
    if (optionsDict != nil) {
        nsUserDefaultsRes = [RadarTripOptions tripOptionsFromDictionary:optionsDict];
    }

    if ((nsUserDefaultsRes && ![nsUserDefaultsRes isEqual:radarKVStoreRes]) || (radarKVStoreRes && ![radarKVStoreRes isEqual:nsUserDefaultsRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarSettings: tripOptions mismatch."];
    }
    return nsUserDefaultsRes;   
}

- (void)doubleWriteRadarTripOptionsSetter:(NSString *)key value:(RadarTripOptions *_Nullable)value {
    [self setObject:value forKey:key];
    if (![RadarSettings useRadarKVStore]) {
        if (!value) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            return;
        }
        NSDictionary *optionsDict = [value dictionaryValue];
        [[NSUserDefaults standardUserDefaults] setObject:optionsDict forKey:key];
    }
}

@end
