//
//  RadarSDKConfiguration.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Represents server-side sdk configuration.
 
 @see https://radar.com/documentation/sdk/ios
 */
@interface RadarSDKConfiguration : NSObject

/**
 
 */
@property (nonatomic, assign) RadarLogLevel logLevel;

/**
 Initializes a new RadarSDKConfiguration object with given value.
 */
- (instancetype)initWithLogLevel:(RadarLogLevel)logLevel;

/**
 Creates a RadarSDKConfiguration object from the provided dictionary.
 
 @param dict A dictionary to extract the settings from.
 */
+ (RadarSDKConfiguration *_Nullable)sdkConfigurationFromDictionary:(NSDictionary *)dict;

/**
 Returns a dictionary representation of the object.
 */
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
