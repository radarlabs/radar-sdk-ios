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

- (NSString *)doubleWriteStringGetter:(NSString *)key;

- (void)doubleWriteStringSetter:(NSString *)key value:(NSString *)value;

- (double)doubleWriteDoubleGetter:(NSString *)key;

- (void)doubleWriteDoubleSetter:(NSString *)key value:(double)value;

- (BOOL)doubleWriteBOOLGetter:(NSString *)key;

- (void)doubleWriteBOOLSetter:(NSString *)key value:(BOOL)value;

- (NSDate *)doubleWriteDateGetter:(NSString *)key;

- (void)doubleWriteDateSetter:(NSString *)key value:(NSDate *)value;

- (NSArray<NSString *> *_Nullable)doubleWriteStringArrayGetter:(NSString *)key;

- (void)doubleWriteStringArraySetter:(NSString *)key value:(NSArray<NSString *> *)value;

- (NSInteger)doubleWriteIntegerGetter:(NSString *)key;

- (void)doubleWriteIntegerSetter:(NSString *)key value:(NSInteger)value;

- (BOOL)doubleWriteKeyExists:(NSString *)key;

- (CLLocation *_Nullable)doubleWriteCLLocationGetter:(NSString *)key;

- (void)doubleWriteCLLocationSetter:(NSString *)key value:(CLLocation *_Nullable)value;

- (RadarTrackingOptions *_Nullable)doubleWriteRadarTrackingOptionGetter:(NSString *)key;

- (void)doubleWriteRadarTrackingOptionSetter:(NSString *)key value:(RadarTrackingOptions *_Nullable)value;

- (RadarTripOptions *_Nullable)doubleWriteRadarTripOptionsGetter:(NSString *)key;

- (void)doubleWriteRadarTripOptionsSetter:(NSString *)key value:(RadarTripOptions *_Nullable)value;

- (NSDictionary *)doubleWriteDictionaryGetter:(NSString *)key;

- (void)doubleWriteDictionarySetter:(NSString *)key value:(NSDictionary *_Nullable)value;
@end

NS_ASSUME_NONNULL_END
