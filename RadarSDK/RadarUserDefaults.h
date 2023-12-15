//
//  RadarUserDefaults.h
//  RadarSDK
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarLog.h"
#import "RadarFileStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarUserDefaults : NSObject

@property (strong, nonatomic) NSString *settingsFileDir;
@property (strong, nonatomic) RadarFileStorage *fileHandler;
@property (nonatomic, assign) BOOL migrationCompleteFlag;

+ (instancetype)sharedInstance;

- (void)setMigrationCompleteFlag:(BOOL)migrationCompleteFlag;

- (BOOL)boolForKey:(NSString *)key;

- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (NSString *)stringForKey:(NSString *)key;

- (void)setString:(NSString *)value forKey:(NSString *)key;

- (NSDictionary *)dictionaryForKey:(NSString *)key;

- (void)setDictionary:(NSDictionary *)value forKey:(NSString *)key;

- (double)doubleForKey:(NSString *)key;

- (void)setDouble:(double)value forKey:(NSString *)key;

- (void)setObject:(NSObject *)value forKey:(NSString *)key;

- (NSObject *)objectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END