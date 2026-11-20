//
//  RadarEvent+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

// Internal Objective-C interface of the Swift-implemented RadarEvent (RadarEvent.swift).
@interface RadarEvent ()

+ (NSArray<RadarEvent *> *_Nullable)eventsFromObject:(id _Nullable)object;
- (instancetype _Nullable)initWithObject:(id _Nullable)object;

@end
