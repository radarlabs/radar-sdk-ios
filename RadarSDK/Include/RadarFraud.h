//
//  RadarFraud.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.

#ifndef RadarFraud_h
#define RadarFraud_h
#import <Foundation/Foundation.h>

@interface RadarFraud : NSObject

/**
 A boolean indicating whether the user's location is being mocked, such as in a simulation. May be `false` if Fraud is not enabled.
 */
@property (nonatomic, readonly) bool mocked;

/**
 A boolean indicating whether the user's IP address is a known proxy. May be `false` if Fraud is not enabled.
 */
@property (nonatomic, readonly) bool proxy;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

#endif /* RadarFraud_h */
