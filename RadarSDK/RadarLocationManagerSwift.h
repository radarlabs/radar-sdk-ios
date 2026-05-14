//
//  RadarLocationManagerSwift.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  ObjC-visible interface for RadarLocationManager methods that have been ported to
//  Swift. The implementation lives in RadarLocationManager+Swift.swift. RadarLocationManager.m
//  imports this header and dispatches to these methods when useSwiftLocationManager is set.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocationManagerSwift : NSObject

+ (void)restartPreviousTrackingOptions;

@end

NS_ASSUME_NONNULL_END
