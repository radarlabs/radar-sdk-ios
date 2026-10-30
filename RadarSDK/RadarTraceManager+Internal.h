//
//  RadarTraceManager+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift RadarTraceManager for Objective-C callers, since internal Swift classes are not emitted
// into RadarSDK-Swift.h.
@interface RadarTraceManager : NSObject

@property (class, nonatomic, readonly) RadarTraceManager *sharedInstance;

// Starts tracing for the process and uploads spans left from a previous one. Later calls do nothing.
- (void)start;

// Uploads persisted spans, if any. Does nothing before -start.
- (void)flushIfStarted;

@end

NS_ASSUME_NONNULL_END
