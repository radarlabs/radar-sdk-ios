//
//  RadarVerificationManager.m
//  RadarSDK
//
//  Created by Nick Patrick on 1/3/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>
#import <DeviceCheck/DeviceCheck.h>
#import <Foundation/Foundation.h>

#import "RadarVerificationManager.h"

@implementation RadarVerificationManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    if ([NSThread isMainThread]) {
        dispatch_once(&once, ^{
            sharedInstance = [self new];
        });
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_once(&once, ^{
                sharedInstance = [self new];
            });
        });
    }
    return sharedInstance;
}

- (void)getAttestationWithNonce:(NSString *)nonce completionHandler:(RadarVerificationCompletionHandler)completionHandler {
    if (@available(iOS 14.0, *)) {
        DCAppAttestService *service = [DCAppAttestService sharedService];

        if (!service.isSupported) {
            completionHandler(nil, nil, @"Service unsupported");

            return;
        }

        if (!nonce) {
            completionHandler(nil, nil, @"Missing nonce");

            return;
        }

        [service generateKeyWithCompletionHandler:^(NSString *_Nullable keyId, NSError *_Nullable error) {
            if (error) {
                completionHandler(nil, nil, error.localizedDescription);

                return;
            }

            NSData *clientData = [nonce dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableData *clientDataHash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
            CC_SHA256([clientData bytes], (CC_LONG)[clientData length], [clientDataHash mutableBytes]);

            [service attestKey:keyId
                   clientDataHash:clientDataHash
                completionHandler:^(NSData *_Nullable attestationObject, NSError *_Nullable error) {
                    NSString *assertionString = [attestationObject base64EncodedStringWithOptions:0];

                    completionHandler(assertionString, keyId, nil);
                }];
        }];
    } else {
        completionHandler(nil, nil, @"OS unsupported");
    }
}

@end
