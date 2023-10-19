//
//  RadarVerificationManager.h
//  RadarSDK
//
//  Created by Nick Patrick on 1/3/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarVerificationManager : NSObject

typedef void (^_Nullable RadarVerificationCompletionHandler)(NSString *_Nullable attestationString, NSString *_Nullable keyId, NSString *_Nullable attestationError);

+ (instancetype)sharedInstance;
- (void)trackVerifiedWithCompletionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler;
- (void)trackVerifiedTokenWithCompletionHandler:(RadarTrackTokenCompletionHandler _Nullable)completionHandler;
- (void)startTrackingVerified:(BOOL)token;
- (void)getAttestationWithNonce:(NSString *)nonce completionHandler:(RadarVerificationCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
