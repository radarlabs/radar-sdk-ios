//
//  RadarAPIClient+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIClient.h"
#import "RadarTraceSpan+Internal.h"

NS_ASSUME_NONNULL_BEGIN

// Traced variants of RadarAPIClient requests. Each creates its request's client span as a child of traceSpan, on the
// branch it actually takes, and sends that span's traceparent. A nil traceSpan means the call isn't traced; the
// overloads in RadarAPIClient.h pass nil.
@interface RadarAPIClient ()

- (void)getConfigForUsage:(NSString *_Nullable)usage
                 verified:(BOOL)verified
 useSecondaryVerifiedHost:(BOOL)useSecondaryVerifiedHost
                traceSpan:(RadarTraceSpan *_Nullable)traceSpan
        completionHandler:(RadarConfigAPICompletionHandler _Nonnull)completionHandler;

- (void)trackWithLocation:(CLLocation *_Nonnull)location
                  stopped:(BOOL)stopped
               foreground:(BOOL)foreground
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
           indoorLocation:(CLLocation *_Nullable)indoorLocation
                traceSpan:(RadarTraceSpan *_Nullable)traceSpan
        completionHandler:(RadarTrackAPICompletionHandler _Nonnull)completionHandler;

- (void)trackWithLocation:(CLLocation *_Nonnull)location
                  stopped:(BOOL)stopped
               foreground:(BOOL)foreground
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
           indoorLocation:(CLLocation *_Nullable)indoorLocation
                 verified:(BOOL)verified
     preparedFraudPayload:(RadarPreparedFraudPayloadWrapper *_Nullable)preparedFraudPayload
      expectedCountryCode:(NSString *_Nullable)expectedCountryCode
        expectedStateCode:(NSString *_Nullable)expectedStateCode
          expectedAddress:(NSString *_Nullable)expectedAddress
                   reason:(NSString *_Nullable)reason
            transactionId:(NSString *_Nullable)transactionId
             revealRiskId:(NSString *_Nullable)revealRiskId
 useSecondaryVerifiedHost:(BOOL)useSecondaryVerifiedHost
                traceSpan:(RadarTraceSpan *_Nullable)traceSpan
        completionHandler:(RadarTrackAPICompletionHandler _Nonnull)completionHandler;

- (void)flushReplays:(NSArray<NSDictionary *> *_Nonnull)replays
           traceSpan:(RadarTraceSpan *_Nullable)traceSpan
   completionHandler:(RadarFlushReplaysAPICompletionHandler _Nonnull)completionHandler;

- (void)searchBeaconsNear:(CLLocation *_Nonnull)near
                   radius:(int)radius
                    limit:(int)limit
                traceSpan:(RadarTraceSpan *_Nullable)traceSpan
        completionHandler:(RadarSearchBeaconsAPICompletionHandler _Nonnull)completionHandler;

@end

NS_ASSUME_NONNULL_END
