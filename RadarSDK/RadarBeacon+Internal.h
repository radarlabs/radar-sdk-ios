//
//  RadarAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarBeacon.h"
#import <Foundation/Foundation.h>

@interface RadarBeacon ()

+ (NSArray<RadarBeacon *> *_Nullable)beaconsFromObject:(id _Nonnull)object;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id uuid:(NSString *_Nonnull)uuid major:(NSString *_Nullable)major minor:(NSString *_Nullable)minor;

@end
