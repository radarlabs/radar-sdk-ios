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

- (void)getEncryptedPayloadWithInstallId:(NSString *)installId
                                 origin:(NSString *_Nullable)origin
                                product:(NSString *_Nullable)product
                             sdkVersion:(NSString *_Nullable)sdkVersion
                          authorization:(NSString *_Nullable)authorization
                      completionHandler:(void (^)(RadarStatus status,
                                                  NSString *_Nullable payload,
                                                  NSError *_Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
