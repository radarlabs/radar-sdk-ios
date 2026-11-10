//
//  RadarConversion+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

// Internal Objective-C interface of the Swift-implemented RadarConversion (RadarConversion.swift).
@interface RadarConversion ()

- (instancetype _Nullable)initWithObject:(id _Nullable)object;

@end
