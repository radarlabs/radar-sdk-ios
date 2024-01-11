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

@implementation RadarKVStore 


static NSString *const kCompletedMigration = @"radar-completed-migration";
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
            self.radarKVStoreMigrationComplete= [self boolForKey:kCompletedMigration];
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

- (nullable NSString *)stringForKey:(NSString *)key {
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

- (void)setString:(nullable NSString *)value forKey:(NSString *)key {
    if (!value) {
        [self.fileHandler deleteFileAtPath:[self getSettingFilePath:key]];
        return;
    }
    [self.fileHandler writeData:[value dataUsingEncoding:NSUTF8StringEncoding] toFileAtPath:[self getSettingFilePath:key]];
}

- (nullable NSDictionary *)dictionaryForKey:(NSString *)key {
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

- (void)setDictionary:(nullable NSDictionary *)value forKey:(NSString *)key {
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

- (nullable NSObject *)objectForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return nil;
    }
    NSObject *value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return value;
}

- (void)setObject:(nullable NSObject *)value forKey:(NSString *)key {
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

@end
