//
//  RadarDelegate.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarEvent.h"
#import "RadarUser.h"

/**
 A delegate for client-side delivery of events and location updates. For more information, see https://radar.io/documentation/sdk.
 
 @see https://radar.io/documentation/sdk
 */
@protocol RadarDelegate <NSObject>

/**
 Tells the delegate that events were received for the current user.
 
 @param events The events received.
 @param user The current user.
 */
- (void)didReceiveEvents:(NSArray<RadarEvent *> * _Nonnull)events user:(RadarUser * _Nonnull)user NS_SWIFT_NAME(didReceiveEvents(_:user:));

@optional

/**
 Tells the delegate that the current user's location was updated.

 @param location The location.
 @param user The current user.
 */
- (void)didUpdateLocation:(CLLocation * _Nonnull)location user:(RadarUser * _Nonnull)user NS_SWIFT_NAME(didUpdateLocation(_:user:));

@optional

/**
 Tells the delegate that a request failed.
 
 @param status The status.
 */
- (void)didFailWithStatus:(RadarStatus)status NS_SWIFT_NAME(didFail(status:));

@optional

/**
 Tells the delegate that client's location was updated, but not necessarily persisted to the server. To receive server-persisted location updates and user state, use `didUpdateLocation:user:` instead.
 
 @param location The location.
 @param stopped A boolean indicating whether the client is stopped.
 */
- (void)didUpdateClientLocation:(CLLocation * _Nonnull)location stopped:(BOOL)stopped NS_SWIFT_NAME(didUpdateClientLocation(_:stopped:));

@end
