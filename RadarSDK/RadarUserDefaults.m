//
//  RadarUserDefaults.m
//  RadarSDK
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarUserDefaults.h"
#import "RadarFileStorage.h"

@implementation RadarUserDefaults 


static NSString *const kCompletedMigration = @"radar-completed-migration";


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
        self.settingsFileDir = [documentsDirectory stringByAppendingPathComponent:@"radar_settings"];
        self.fileHandler = [[RadarFileStorage alloc] init];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.settingsFileDir isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.settingsFileDir withIntermediateDirectories:YES attributes:nil error:nil];
            self.migrationCompleteFlag = NO;
        } else {
            self.migrationCompleteFlag= [self boolForKey:kCompletedMigration];
        }
    }
    return self;
}

- (NSString *)getSettingFilePath:(NSString *)key {
    return [self.settingsFileDir stringByAppendingPathComponent:key];
}

- (void)setMigrationCompleteFlag:(BOOL)migrationCompleteFlag {
    _migrationCompleteFlag = migrationCompleteFlag;
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

- (NSString *)stringForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return nil;
    }
    NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //handle string was encoded as nsobject
    if (!value) {
        value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return value;
}

- (void)setString:(NSString *)value forKey:(NSString *)key {
    //check that value is non null
    if (!value) {
        return;
    }
    [self.fileHandler writeData:[value dataUsingEncoding:NSUTF8StringEncoding] toFileAtPath:[self getSettingFilePath:key]];
}

- (NSDictionary *)dictionaryForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return nil;
    }
    //This is sus, need to look into serization of objects
    NSDictionary *value = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return value;
}

- (void)setDictionary:(NSDictionary *)value forKey:(NSString *)key {
    if (!value) {
        return;
    }
    [self.fileHandler writeData:[NSJSONSerialization dataWithJSONObject:value options:0 error:nil] toFileAtPath:[self getSettingFilePath:key]];
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

- (NSObject *)objectForKey:(NSString *)key {
    NSData *data = [self.fileHandler readFileAtPath: [self getSettingFilePath:key]];
    if (!data) {
        return nil;
    }
    //need to implement nsencoding for all that uses it?
    NSObject *value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return value;
}

- (void)setObject:(NSObject *)value forKey:(NSString *)key {
    if (!value) {
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
        return -1;
    }
    NSInteger value;
    [data getBytes:&value length:sizeof(value)];
    return value;
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    [self.fileHandler writeData:[NSData dataWithBytes:&value length:sizeof(value)] toFileAtPath:[self getSettingFilePath:key]];
}

- (void) removeAllObjects {
    NSArray<NSString *> *allSettings = [self.fileHandler allFilesInDirectory:self.settingsFileDir];
    for (NSString *setting in allSettings) {
        [self.fileHandler deleteFileAtPath:[self getSettingFilePath:setting]];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:self.settingsFileDir withIntermediateDirectories:YES attributes:nil error:nil];
}

- (BOOL)keyExists:(NSString *)key {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self getSettingFilePath:key]];
}

@end
