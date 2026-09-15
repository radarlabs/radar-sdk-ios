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

- (void)prepareBody:(NSDictionary<NSString *, id> *)body
           headers:(NSDictionary<NSString *, NSString *> *)headers
 completionHandler:(void (^)(RadarStatus status,
                             NSDictionary<NSString *, id> *_Nullable body,
                             NSError *_Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
