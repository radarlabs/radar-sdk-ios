//
//  RadarSdkConfiguration.h
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
@interface RadarSdkConfiguration : NSObject

@property (nonatomic, assign) RadarLogLevel logLevel;

@property (nonatomic, assign) BOOL startTrackingOnInitialize;

@property (nonatomic, assign) BOOL trackOnceOnInitialize;

@property (nonatomic, assign) BOOL trackOnceOnResume;

/**
 Initializes a new RadarSdkConfiguration object with given value.
 */
- (instancetype)initWithLogLevel:(RadarLogLevel)logLevel
       startTrackingOnInitialize:(BOOL)startTrackingOnInitialize
           trackOnceOnInitialize:(BOOL)trackOnceOnInitialize
               trackOnceOnResume:(BOOL)trackOnceOnResume;

/**
 Creates a RadarSdkConfiguration object from the provided dictionary.
 
 @param dict A dictionary to extract the settings from.
 */
+ (RadarSdkConfiguration *_Nullable)sdkConfigurationFromDictionary:(NSDictionary *_Nullable)dict;

/**
 Returns a dictionary representation of the object.
 */
- (NSDictionary *)dictionaryValue;

+ (void)updateSdkConfigurationFromServer;

@end

NS_ASSUME_NONNULL_END
