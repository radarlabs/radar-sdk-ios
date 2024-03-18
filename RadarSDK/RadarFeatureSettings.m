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
    useRadarModifiedBackgroundLocation:(BOOL)useRadarModifiedBackgroundLocation {
    if (self = [super init]) {
        _usePersistence = usePersistence;
        _extendFlushReplays = extendFlushReplays;
        _useLogPersistence = useLogPersistence;
        _useRadarModifiedBackgroundLocation = useRadarModifiedBackgroundLocation;
    }
    return self;
}

+ (RadarFeatureSettings *_Nullable)featureSettingsFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return [[RadarFeatureSettings alloc] initWithUsePersistence:NO 
                                                 extendFlushReplays:NO
                                                  useLogPersistence:NO
                                 useRadarModifiedBackgroundLocation:NO];
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
    
    NSObject *useRadarModifiedBackgroundLocationObj = dict[@"useRadarModifiedBackgroundLocation"];
    BOOL useRadarModifiedBackgroundLocation = NO;
    if (useRadarModifiedBackgroundLocationObj && [useRadarModifiedBackgroundLocationObj isKindOfClass:[NSNumber class]]) {
        useRadarModifiedBackgroundLocation = [(NSNumber *)useRadarModifiedBackgroundLocationObj boolValue];
    }

    return [[RadarFeatureSettings alloc] initWithUsePersistence:usePersistence 
                                             extendFlushReplays:extendFlushReplays
                                              useLogPersistence:useLogPersistence
                             useRadarModifiedBackgroundLocation:useRadarModifiedBackgroundLocation];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.usePersistence) forKey:@"usePersistence"];
    [dict setValue:@(self.extendFlushReplays) forKey:@"extendFlushReplays"];
    [dict setValue:@(self.useLogPersistence) forKey:@"useLogPersistence"];
    [dict setValue:@(self.useRadarModifiedBackgroundLocation) forKey:@"useRadarModifiedBackgroundLocation"];
    
    return dict;
}

@end
