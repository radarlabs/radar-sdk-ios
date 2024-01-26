//
//  RadarFeatureSettings.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents server-side feature settings.
 
 @see https://radar.com/documentation/sdk/ios
 */
@interface RadarFeatureSettings : NSObject

/**
 Flag indicating whether to use persistence.
 */
@property (nonatomic, assign) BOOL usePersistence;
@property (nonatomic, assign) BOOL extendFlushReplays;
@property (nonatomic, assign) BOOL useLogPersistence;
@property (nonatomic, assign) BOOL useRadarBeaconRangingOnly;

/**
 Initializes a new RadarFeatureSettings object with given value.
 
 @param usePersistence A flag indicating whether to use persistence.
 */
- (instancetype)initWithUsePersistence:(BOOL)usePersistence
                    extendFlushReplays:(BOOL)extendFlushReplays
                     useLogPersistence:(BOOL)useLogPersistence
             useRadarBeaconRangingOnly:(BOOL)useRadarBeaconRangingOnly;

/**
 Creates a RadarFeatureSettings object from the provided dictionary.
 
 @param dict A dictionary to extract the settings from.
 */
+ (RadarFeatureSettings *_Nullable)featureSettingsFromDictionary:(NSDictionary *)dict;

/**
 Returns a dictionary representation of the object.
 */
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
