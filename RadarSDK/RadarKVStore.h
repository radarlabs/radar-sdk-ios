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

- (NSString *)wrappedStringGetter:(NSString *)key;

- (void)wrappedStringSetter:(NSString *)key value:(NSString *)value;

- (double)wrappedDoubleGetter:(NSString *)key;

- (void)wrappedDoubleSetter:(NSString *)key value:(double)value;

- (BOOL)wrappedBOOLGetter:(NSString *)key;

- (void)wrappedBOOLSetter:(NSString *)key value:(BOOL)value;

- (NSDate *)wrappedDateGetter:(NSString *)key;

- (void)wrappedDateSetter:(NSString *)key value:(NSDate *)value;

- (NSArray<NSString *> *_Nullable)wrappedStringArrayGetter:(NSString *)key;

- (void)wrappedStringArraySetter:(NSString *)key value:(NSArray<NSString *> *)value;

- (NSInteger)wrappedIntegerGetter:(NSString *)key;

- (void)wrappedIntegerSetter:(NSString *)key value:(NSInteger)value;

- (BOOL)wrappedKeyExists:(NSString *)key;

- (CLLocation *_Nullable)wrappedCLLocationGetter:(NSString *)key;

- (void)wrappedCLLocationSetter:(NSString *)key value:(CLLocation *_Nullable)value;

- (RadarTrackingOptions *_Nullable)wrappedRadarTrackingOptionGetter:(NSString *)key;

- (void)wrappedRadarTrackingOptionSetter:(NSString *)key value:(RadarTrackingOptions *_Nullable)value;

- (RadarTripOptions *_Nullable)wrappedRadarTripOptionsGetter:(NSString *)key;

- (void)wrappedRadarTripOptionsSetter:(NSString *)key value:(RadarTripOptions *_Nullable)value;

- (NSDictionary *)wrappedDictionaryGetter:(NSString *)key;

- (void)wrappedDictionarySetter:(NSString *)key value:(NSDictionary *_Nullable)value;
@end

NS_ASSUME_NONNULL_END
