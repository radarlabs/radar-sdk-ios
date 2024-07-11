//
//  RadarInitializeOptions.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A class to hold additional initialization data.
 @see https://radar.com/documentation/sdk/ios
 */
@interface RadarInitializeOptions : NSObject

/**
 An optional stable unique ID for the user to set. No-op if `nil`.
 */
@property (nullable, copy, nonatomic) NSString *userId;

/**
 An optional set of custom key-value pairs for the user. Must have 16 or fewer keys and values of type string, boolean, or number. No-op if `nil`.
 */
@property (nullable, copy, nonatomic) NSDictionary *metadata;

// Add a property for the completion handler. This handler is optional and can be used to execute code after initialization.
// The completion handler takes no parameters and returns void.
@property (nullable, copy, nonatomic) void (^requestBackgroundLocationPermissionCompletionHandler)(void);

+ (RadarInitializeOptions *_Nonnull)fromDictionary:(NSDictionary *_Nullable)dictionary;
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
