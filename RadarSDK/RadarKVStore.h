//
//  RadarKVStore.h
//  RadarSDK
//
//  Created by Kenny Hu on 12/14/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarLog.h"
#import "RadarFileStorage.h"
#import "RadarTrackingOptions.h"
#import "RadarTripOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarKVStore : NSObject

@property (strong, nonatomic) NSString *settingsFileDir;
@property (strong, nonatomic) RadarFileStorage *fileHandler;
@property (nonatomic, assign) BOOL radarKVStoreMigrationComplete;

+ (instancetype)sharedInstance;

- (void)setRadarKVStoreMigrationComplete:(BOOL)migrationCompleteFlag;

- (BOOL)boolForKey:(NSString *)key;

- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (NSString *_Nullable)stringForKey:(NSString *)key;

- (void)setString:(NSString *_Nullable)value forKey:(NSString *)key;

- (NSDictionary *_Nullable)dictionaryForKey:(NSString *)key;

- (void)setDictionary:(NSDictionary *_Nullable)value forKey:(NSString *)key;

- (double)doubleForKey:(NSString *)key;

- (void)setDouble:(double)value forKey:(NSString *)key;

- (void)setInteger:(NSInteger)value forKey:(NSString *)key;

- (NSInteger)integerForKey:(NSString *)key;

- (void)setObject:(NSObject *_Nullable)value forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (NSObject *_Nullable)objectForKey:(NSString *)key;

- (void)removeAllObjects;

- (BOOL)keyExists:(NSString *)key;

- (NSString *)wrappedGetString:(NSString *)key;

- (void)wrappedSetString:(NSString *)key value:(NSString *)value;

- (double)wrappedGetDouble:(NSString *)key;

- (void)wrappedSetDouble:(NSString *)key value:(double)value;

- (BOOL)wrappedGetBOOL:(NSString *)key;

- (void)wrappedSetBOOL:(NSString *)key value:(BOOL)value;

- (NSDate *)wrappedGetDate:(NSString *)key;

- (void)wrappedSetDate:(NSString *)key value:(NSDate *)value;

- (NSArray<NSString *> *_Nullable)wrappedGetStringArray:(NSString *)key;

- (void)wrappedSetStringArray:(NSString *)key value:(NSArray<NSString *> *)value;

- (NSInteger)wrappedGetInteger:(NSString *)key;

- (void)wrappedSetInteger:(NSString *)key value:(NSInteger)value;

- (BOOL)wrappedKeyExists:(NSString *)key;

- (CLLocation *_Nullable)wrappedGetCLLocation:(NSString *)key;

- (void)wrappedSetCLLocation:(NSString *)key value:(CLLocation *_Nullable)value;

- (RadarTrackingOptions *_Nullable)wrappedGetRadarTrackingOptions:(NSString *)key;

- (void)wrappedSetRadarTrackingOptions:(NSString *)key value:(RadarTrackingOptions *_Nullable)value;

- (RadarTripOptions *_Nullable)wrappedGetRadarTripOptions:(NSString *)key;

- (void)wrappedSetRadarTripOptions:(NSString *)key value:(RadarTripOptions *_Nullable)value;

- (NSDictionary *)wrappedGetDictionary:(NSString *)key;

- (void)wrappedSetDictionary:(NSString *)key value:(NSDictionary *_Nullable)value;
@end

NS_ASSUME_NONNULL_END
