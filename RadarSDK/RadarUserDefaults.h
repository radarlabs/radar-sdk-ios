//
//  RadarUserDefaults.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  ObjC-visible interface for the Swift RadarUserDefaults storage funnel. The
//  implementation lives in RadarUserDefaults.swift, which is internal to the module and
//  therefore absent from the public RadarSDK-Swift.h. ObjC accessors that have not yet
//  migrated to the Swift `Key`-typed API import this header to reach the same
//  app-group-aware backing store the Swift funnel uses.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarUserDefaults : NSObject

+ (NSUserDefaults *)sharedUserDefaults;

@end

NS_ASSUME_NONNULL_END
