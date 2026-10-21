//
//  RadarVerifiedLocationToken+Internal.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import "RadarUser.h"
#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarVerifiedLocationToken ()

- (instancetype _Nonnull)initWithUser:(RadarUser *_Nonnull)user
                               events:(NSArray<RadarEvent *> *_Nonnull)events
                                token:(NSString *_Nonnull)token
                            expiresAt:(NSDate *_Nonnull)expiresAt
                            expiresIn:(NSTimeInterval)expiresIn
                               passed:(BOOL)passed
                       failureReasons:(NSArray<NSString *> *_Nonnull)failureReasons
                                  _id:(NSString *_Nullable)_id
                             fullDict:(NSDictionary *_Nonnull)fullDict;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
