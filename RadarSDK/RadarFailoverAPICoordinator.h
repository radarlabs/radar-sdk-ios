//
//  RadarFailoverAPICoordinator.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarFailoverAPICoordinator : NSObject

+ (instancetype)verifiedSharedInstance;

- (void)requestWithPath:(NSString *)path
         performRequest:(void (^)(NSString *url, void (^completion)(RadarStatus status, NSDictionary<NSObject *, id> *_Nullable res)))performRequest
      completionHandler:(void (^)(RadarStatus status, NSDictionary<NSObject *, id> *_Nullable res))completionHandler;

@end

NS_ASSUME_NONNULL_END
