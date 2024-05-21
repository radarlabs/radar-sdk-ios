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
           useLocationMetadata:(BOOL)useLocationMetadata
             useLogPersistence:(BOOL)useLogPersistence {
    if (self = [super init]) {
        _usePersistence = usePersistence;
        _extendFlushReplays = extendFlushReplays;
        _useLocationMetadata = useLocationMetadata;
        _useLogPersistence = useLogPersistence;
    }
    return self;
}

+ (RadarFeatureSettings *_Nullable)featureSettingsFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return [[RadarFeatureSettings alloc] initWithUsePersistence:NO extendFlushReplays:NO useLocationMetadata:NO useLogPersistence:NO];
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

    NSObject *useLocationMetadataObj = dict[@"useLocationMetadata"];
    BOOL useLocationMetadata = NO;
    if (useLocationMetadataObj && [useLocationMetadataObj isKindOfClass:[NSNumber class]]) {
        useLocationMetadata = [(NSNumber *)useLocationMetadataObj boolValue];
    }

    NSObject *useLogPersistenceObj = dict[@"useLogPersistence"]; 
    BOOL useLogPersistence = NO;
    if (useLogPersistenceObj && [useLogPersistenceObj isKindOfClass:[NSNumber class]]) {
        useLogPersistence = [(NSNumber *)useLogPersistenceObj boolValue];
    }

    return [[RadarFeatureSettings alloc] initWithUsePersistence:usePersistence extendFlushReplays:extendFlushReplays useLocationMetadata:useLocationMetadata useLogPersistence:useLogPersistence];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.usePersistence) forKey:@"usePersistence"];
    [dict setValue:@(self.extendFlushReplays) forKey:@"extendFlushReplays"];
    [dict setValue:@(self.useLocationMetadata) forKey:@"useLocationMetadata"];
    [dict setValue:@(self.useLogPersistence) forKey:@"useLogPersistence"];
    
    return dict;
}

@end
