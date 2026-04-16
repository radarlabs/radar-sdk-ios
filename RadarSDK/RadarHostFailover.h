//
//  RadarHostFailover.h
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarHostFailover : NSObject

/// Initialize with an ordered list of hosts. Index 0 is the primary host.
- (instancetype)initWithHosts:(NSArray<NSString *> *)hosts;

/// Returns the host to use for the next request.
/// In normal mode, returns the primary host.
/// In failover mode with backoff not elapsed, returns the current fallback host.
/// In failover mode with backoff elapsed, returns the primary host (probe attempt).
- (NSString *)currentHost;

/// Call after a successful request. If we were probing the primary, resets to normal mode.
- (void)reportSuccess;

/// Call after a network error that should trigger failover.
/// Advances to the next host if available.
/// Returns YES if a different host is available to retry on.
- (BOOL)reportFailure;

@end

NS_ASSUME_NONNULL_END
