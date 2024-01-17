//
//  RadarFeatureSettings.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "RadarFeatureSettings.h"

@implementation RadarFeatureSettings

- (instancetype)initWithUsePersistence:(BOOL)usePersistence
                    extendFlushReplays:(BOOL)extendFlushReplays
                     useLogPersistence:(BOOL)useLogPersistence
                       useRadarKVStore:(BOOL)useRadarKVStore {
    if (self = [super init]) {
        _usePersistence = usePersistence;
        _extendFlushReplays = extendFlushReplays;
        _useLogPersistence = useLogPersistence;
        _useRadarKVStore = useRadarKVStore;
    }
    return self;
}

+ (RadarFeatureSettings *_Nullable)featureSettingsFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLogPersistence:NO useRadarKVStore:NO];
    }

    NSObject *usePersistenceObj = dict[@"usePersistence"]; 
    BOOL usePersistence = NO;
    if (usePersistenceObj && [usePersistenceObj isKindOfClass:[NSNumber class]]) {
        usePersistence = [(NSNumber *)usePersistenceObj boolValue];
    }

    NSObject *extendFlushReplaysObj = dict[@"extendFlushReplays"];
    BOOL extendFlushReplays = NO;
    if (extendFlushReplaysObj && [extendFlushReplaysObj isKindOfClass:[NSNumber class]]) {
       extendFlushReplays = [(NSNumber *)extendFlushReplaysObj boolValue]; 
    }

    NSObject *useLogPersistenceObj = dict[@"useLogPersistence"]; 
    BOOL useLogPersistence = NO;
    if (useLogPersistenceObj && [useLogPersistenceObj isKindOfClass:[NSNumber class]]) {
        useLogPersistence = [(NSNumber *)useLogPersistenceObj boolValue];
    }

    NSObject *useRadarKVStoreObj = dict[@"useRadarKVStore"];
    BOOL useRadarKVStore = NO;
    if (useRadarKVStoreObj && [useRadarKVStoreObj isKindOfClass:[NSNumber class]]) {
        useRadarKVStore = [(NSNumber *)useRadarKVStoreObj boolValue];
    }

    return [[RadarFeatureSettings alloc] initWithUsePersistence:usePersistence extendFlushReplays:extendFlushReplays useLogPersistence:useLogPersistence useRadarKVStore:useRadarKVStore];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.usePersistence) forKey:@"usePersistence"];
    [dict setValue:@(self.extendFlushReplays) forKey:@"extendFlushReplays"];
    [dict setValue:@(self.useLogPersistence) forKey:@"useLogPersistence"];
    [dict setValue:@(self.useRadarKVStore) forKey:@"useRadarKVStore"];
    
    return dict;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RadarFeatureSettings class]]) {
        return NO;
    }

    RadarFeatureSettings *settings = (RadarFeatureSettings *)object;
    return self.usePersistence == settings.usePersistence && self.extendFlushReplays == settings.extendFlushReplays && self.useLogPersistence == settings.useLogPersistence && self.useRadarKVStore == settings.useRadarKVStore;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [RadarFeatureSettings featureSettingsFromDictionary:[coder decodeObjectForKey:@"dictionaryValue"]];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self dictionaryValue] forKey:@"dictionaryValue"];
}

@end
