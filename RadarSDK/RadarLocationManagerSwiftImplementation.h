//
//  RadarLocationManagerSwiftImplementation.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarLocationManagerImplementation.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocationManagerSwiftImplementation : NSObject <RadarLocationManagerImplementation>

- (instancetype)initWithImplementation:(NSObject *)implementation;

@end

NS_ASSUME_NONNULL_END
