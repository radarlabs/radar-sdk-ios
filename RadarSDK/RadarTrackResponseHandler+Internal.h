//
//  RadarTrackResponseHandler+Internal.h
//  RadarSDK
//
//  Created by Alan Charles on 11/12/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radar.h"

@class RadarVerifiedLocationToken;

NS_ASSUME_NONNULL_BEGIN

@interface RadarTrackResponseHandler : NSObject

+ (BOOL)handleResponse:(NSDictionary *)response
             verified:(BOOL)verified
    requestedVerificationLevel:(RadarVerificationLevel)requestedVerificationLevel
    completionHandler:(void (^)(RadarStatus status,
                                NSDictionary *_Nullable response,
                                RadarVerifiedLocationToken *_Nullable token))completionHandler;

@end

NS_ASSUME_NONNULL_END
