//
//  RadarTraceManager+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RadarTraceSpan;

// Declares the internal Swift RadarTraceManager for Objective-C callers, since internal Swift classes are not emitted
// into RadarSDK-Swift.h.
@interface RadarTraceManager : NSObject

@property (class, nonatomic, readonly) RadarTraceManager *sharedInstance;

// Starts tracing for the process: deletes pending spans from every session except the current one, then uploads
// stored spans. Later calls do nothing.
- (void)start;

// Uploads persisted spans, if any. Does nothing before -start.
- (void)flush;

// Flushes when span ends, so the upload includes it, or now if span is nil, doesn't record, or has ended.
- (void)flushAfterSpan:(RadarTraceSpan *_Nullable)span;

// Applies the server's sampling decision for sessionId, which must be the session sent with the request, not the
// current one. Only a session's first decision counts. A sampled decision flushes after flushAfterSpan ends.
- (void)onSamplingDecisionForSessionId:(NSString *)sessionId sampled:(BOOL)sampled flushAfter:(RadarTraceSpan *_Nullable)span;

@end

NS_ASSUME_NONNULL_END
