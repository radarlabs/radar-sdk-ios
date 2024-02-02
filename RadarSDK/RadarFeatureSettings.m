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
   radarLowPowerManagerDesiredAccuracy:(double)radarLowPowerManagerDesiredAccuracy
    radarLowPowerManagerDistanceFilter:(double)radarLowPowerManagerDistanceFilter {
    if (self = [super init]) {
        _usePersistence = usePersistence;
        _extendFlushReplays = extendFlushReplays;
        _useLogPersistence = useLogPersistence;
        _radarLowPowerManagerDesiredAccuracy = radarLowPowerManagerDesiredAccuracy;
        _radarLowPowerManagerDistanceFilter = radarLowPowerManagerDistanceFilter;
    }
    return self;
}

+ (RadarFeatureSettings *_Nullable)featureSettingsFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return [[RadarFeatureSettings alloc] initWithUsePersistence:NO
                                                 extendFlushReplays:NO
                                                  useLogPersistence:NO
                                radarLowPowerManagerDesiredAccuracy:3000
                                 radarLowPowerManagerDistanceFilter:3000];
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
    
    NSObject *radarLowPowerManagerDesiredAccuracyObj = dict[@"radarLowPowerManagerDesiredAccuracy"];
    double radarLowPowerManagerDesiredAccuracy = 3000;
    if (radarLowPowerManagerDesiredAccuracyObj && [radarLowPowerManagerDesiredAccuracyObj isKindOfClass:[NSNumber class]]) {
        radarLowPowerManagerDesiredAccuracy = [(NSNumber *)radarLowPowerManagerDesiredAccuracyObj doubleValue];
    }
    
    NSObject *radarLowPowerManagerDistanceFilterObj = dict[@"radarLowPowerManagerDistanceFilter"];
    double radarLowPowerManagerDistanceFilter = 3000;
    if (radarLowPowerManagerDistanceFilterObj && [radarLowPowerManagerDistanceFilterObj isKindOfClass:[NSNumber class]]) {
        radarLowPowerManagerDistanceFilter = [(NSNumber *)radarLowPowerManagerDistanceFilterObj doubleValue];
    }

    return [[RadarFeatureSettings alloc] initWithUsePersistence:usePersistence
                                             extendFlushReplays:extendFlushReplays
                                              useLogPersistence:useLogPersistence
                            radarLowPowerManagerDesiredAccuracy:radarLowPowerManagerDesiredAccuracy
                             radarLowPowerManagerDistanceFilter:radarLowPowerManagerDistanceFilter];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:@(self.usePersistence) forKey:@"usePersistence"];
    [dict setValue:@(self.extendFlushReplays) forKey:@"extendFlushReplays"];
    [dict setValue:@(self.useLogPersistence) forKey:@"useLogPersistence"];
    [dict setValue:@(self.radarLowPowerManagerDesiredAccuracy) forKey:@"radarLowPowerManagerDesiredAccuracy"];
    [dict setValue:@(self.radarLowPowerManagerDistanceFilter) forKey:@"radarLowPowerManagerDistanceFilter"];
    
    return dict;
}

@end
