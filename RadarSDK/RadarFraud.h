//
//  RadarFraud.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.

#ifndef RadarFraud_h
#define RadarFraud_h
#import <Foundation/Foundation.h>

@interface RadarFraud : NSObject

@property (nonatomic, readonly) bool mocked;

@property (nonatomic, readonly) bool proxy;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

#endif /* RadarFraud_h */
