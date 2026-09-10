//
//  RadarTrackVerifiedRequestPreparer.h
//  RadarSDK
//
//  Created by Alan Charles on 9/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarAPIHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarTrackVerifiedRequestPreparer : NSObject

- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options;

- (void)prepareRequest:(NSURLRequest *)request
    completionHandler:(RadarRequestPreparationCompletion)completionHandler;

@end

NS_ASSUME_NONNULL_END
