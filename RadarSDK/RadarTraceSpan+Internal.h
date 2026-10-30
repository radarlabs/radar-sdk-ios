//
//  RadarTraceSpan+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift RadarTraceSpan for Objective-C callers, since internal Swift classes are not emitted
// into RadarSDK-Swift.h.
@interface RadarTraceSpan : NSObject

// Starts a new trace with this span as its root, or returns the no-op span if tracing is off.
+ (RadarTraceSpan *)startWithName:(NSString *)name;

// Starts a child span for work inside the SDK. Children of the no-op span are the same no-op span.
- (RadarTraceSpan *)child:(NSString *)name;

// Starts a child span for a request to the Radar API. Send its traceparent with the request.
- (RadarTraceSpan *)clientChild:(NSString *)name;

// The W3C traceparent header for requests made in this span. Nil for the no-op span.
@property (nonatomic, readonly, copy, nullable) NSString *traceparent;

// Attribute setters. Ignored on the no-op span and after -endWithStatus:.
- (void)setString:(NSString *)value forKey:(NSString *)key;
- (void)setInteger:(int64_t)value forKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

// Ends the span and records it. Only the first call has an effect.
- (void)endWithStatus:(RadarStatus)status;

@end

NS_ASSUME_NONNULL_END
