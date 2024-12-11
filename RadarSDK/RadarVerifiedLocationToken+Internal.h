//
//  RadarVerifiedLocationToken+Internal.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarVerifiedLocationToken.h"
#import <Foundation/Foundation.h>

@interface RadarVerifiedLocationToken ()

- (instancetype _Nullable)initWithUser:(RadarUser *_Nonnull)user
                                events:(NSArray<RadarEvent *> *_Nonnull)events
                                 token:(NSString *_Nonnull)token
                             expiresAt:(NSDate *_Nonnull)expiresAt
                             expiresIn:(NSTimeInterval)expiresIn
                                passed:(BOOL)passed
                        failureReasons:(NSArray<NSString *> *_Nonnull)failureReasons
                                   _id:(NSString *_Nonnull)_id
                              fullDict:(NSDictionary *_Nonnull)fullDict;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
