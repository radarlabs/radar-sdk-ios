//
//  RadarMeta.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  ObjC-visible interface for RadarMeta. The implementation lives in RadarMeta.swift.
//  RadarSDK-Swift.h only exposes public Swift declarations (BUILD_LIBRARY_FOR_DISTRIBUTION
//  is enabled for this target), so any internal Swift type read from ObjC — RadarMeta
//  included — needs a hand-maintained header like this one, mirroring the
//  RadarLocationManagerSwift.h / RadarSdkConfiguration.h pattern.
//

#import "RadarSdkConfiguration.h"
#import "RadarTrackingOptions.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarMeta : NSObject

@property (nullable, strong, nonatomic, readwrite) RadarTrackingOptions *trackingOptions;
@property (nullable, strong, nonatomic, readwrite) RadarSdkConfiguration *sdkConfiguration;

+ (RadarMeta *_Nullable)fromDictionary:(NSDictionary *_Nullable)dict;

@end

NS_ASSUME_NONNULL_END
