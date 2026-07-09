//
//  RadarIndoors.h
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarUser.h"

@interface RadarIndoors : NSObject

+ (RadarIndoors * _Nonnull)shared;

- (void)updateTrackingWithUser:(RadarUser * _Nonnull)user completionHandler:(void (^ _Nonnull)(void))completionHandler;
- (void)getLocationWithCompletionHandler:(void (^ _Nonnull)(CLLocation * _Nullable))completionHandler;
- (nonnull instancetype)init;
@end
