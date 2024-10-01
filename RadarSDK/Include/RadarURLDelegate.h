//
//  RadarURLDelegate.h
//  RadarSDK
//
//  Created by Kenny Hu on 10/1/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A delegate for client-side delivery of events, location updates, and debug logs. For more information, see https://radar.com/documentation/sdk/ios

 @see https://radar.com/documentation/sdk/ios
 */
@protocol RadarURLDelegate<NSObject>

/**
 Tells the delegate that events were received.

 @param events The events received.
 @param user The user, if any.
 */
- (BOOL)didHandleURL:(NSURL *)url NS_SWIFT_NAME(didHandleURL(_:));

@end

NS_ASSUME_NONNULL_END
