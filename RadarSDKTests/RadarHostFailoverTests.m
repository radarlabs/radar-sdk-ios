//
//  RadarHostFailoverTests.m
//  RadarSDKTests
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RadarHostFailover.h"

@interface RadarHostFailoverTests : XCTestCase
@end

@implementation RadarHostFailoverTests

static NSString *const kPrimary = @"api.radar.io";
static NSString *const kFallback1 = @"api-fallback1.radar.io";
static NSString *const kFallback2 = @"api-fallback2.radar.io";

#pragma mark - Initial state

- (void)test_currentHost_returnsPrimaryInitially {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    XCTAssertEqualObjects([failover currentHost], kPrimary);
}

- (void)test_currentHost_singleHost {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary]];
    XCTAssertEqualObjects([failover currentHost], kPrimary);
}

#pragma mark - reportFailure

- (void)test_reportFailure_returnsTrueWhenAlternateAvailable {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    BOOL hasAlternate = [failover reportFailure];
    XCTAssertTrue(hasAlternate);
}

- (void)test_reportFailure_switchesToFallback {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1, kFallback2]];
    [failover reportFailure];
    XCTAssertEqualObjects([failover currentHost], kFallback1);
}

- (void)test_reportFailure_returnsFalseOnLastHost {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary]];
    BOOL hasAlternate = [failover reportFailure];
    XCTAssertFalse(hasAlternate);
}

- (void)test_reportFailure_advancesThroughAllHosts {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1, kFallback2]];

    BOOL first = [failover reportFailure];
    XCTAssertTrue(first);
    XCTAssertEqualObjects([failover currentHost], kFallback1);

    BOOL second = [failover reportFailure];
    XCTAssertTrue(second);
    XCTAssertEqualObjects([failover currentHost], kFallback2);

    BOOL third = [failover reportFailure];
    XCTAssertFalse(third);
}

#pragma mark - reportSuccess

- (void)test_reportSuccess_normalModeDoesNotChangeHost {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportSuccess];
    XCTAssertEqualObjects([failover currentHost], kPrimary);
}

- (void)test_reportSuccess_notProbingStaysOnFallback {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure];
    // Within backoff so not probing; reportSuccess should not reset to primary
    [failover reportSuccess];
    XCTAssertEqualObjects([failover currentHost], kFallback1);
}

#pragma mark - Probing behavior

- (void)test_currentHost_probesPrimaryAfterBackoff {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure];

    // Simulate backoff elapsed
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-60] forKey:@"lastFailureTime"];

    XCTAssertEqualObjects([failover currentHost], kPrimary);
}

- (void)test_reportSuccess_afterProbeResetsToPrimary {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure];

    // Simulate backoff elapsed and trigger probe
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-60] forKey:@"lastFailureTime"];
    NSString *host = [failover currentHost];
    XCTAssertEqualObjects(host, kPrimary);

    // Probe succeeds
    [failover reportSuccess];
    XCTAssertEqualObjects([failover currentHost], kPrimary);
}

- (void)test_reportFailure_probeFailedDoublesBackoff {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure];

    // Simulate backoff elapsed to trigger probe
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-60] forKey:@"lastFailureTime"];
    [failover currentHost]; // sets isProbingPrimary = YES

    // Probe fails
    BOOL hasAlternate = [failover reportFailure];
    XCTAssertTrue(hasAlternate);

    // Backoff should have doubled from 30 to 60
    NSTimeInterval currentBackoff = [[failover valueForKey:@"currentBackoff"] doubleValue];
    XCTAssertEqual(currentBackoff, 60.0);
}

- (void)test_backoffCapsAt300Seconds {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure];

    // Repeatedly probe and fail: 30 -> 60 -> 120 -> 240 -> 300 (cap)
    for (int i = 0; i < 10; i++) {
        [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-600] forKey:@"lastFailureTime"];
        [failover currentHost]; // trigger probe
        [failover reportFailure]; // probe fails, doubles backoff
    }

    NSTimeInterval currentBackoff = [[failover valueForKey:@"currentBackoff"] doubleValue];
    XCTAssertEqual(currentBackoff, 300.0);
}

- (void)test_reportSuccess_resetsBackoffToInitial {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure];

    // Drive backoff up
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-60] forKey:@"lastFailureTime"];
    [failover currentHost];
    [failover reportFailure]; // backoff now 60

    // Probe again and succeed
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-120] forKey:@"lastFailureTime"];
    [failover currentHost];
    [failover reportSuccess];

    NSTimeInterval currentBackoff = [[failover valueForKey:@"currentBackoff"] doubleValue];
    XCTAssertEqual(currentBackoff, 30.0);
}

#pragma mark - Fallback during backoff

- (void)test_currentHost_returnsFallbackDuringBackoff {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure];

    // lastFailureTime is now, so backoff hasn't elapsed
    XCTAssertEqualObjects([failover currentHost], kFallback1);
    XCTAssertEqualObjects([failover currentHost], kFallback1);
}

#pragma mark - Full failover cycle

- (void)test_fullCycle_failoverProbeRecover {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1, kFallback2]];

    // 1. Start on primary
    XCTAssertEqualObjects([failover currentHost], kPrimary);

    // 2. Primary fails, move to fallback1
    [failover reportFailure];
    XCTAssertEqualObjects([failover currentHost], kFallback1);

    // 3. Backoff elapses, probe primary
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-60] forKey:@"lastFailureTime"];
    XCTAssertEqualObjects([failover currentHost], kPrimary);

    // 4. Probe fails, stay on fallback1 with doubled backoff
    [failover reportFailure];
    XCTAssertEqualObjects([failover currentHost], kFallback1);

    // 5. Backoff elapses again, probe primary
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-120] forKey:@"lastFailureTime"];
    XCTAssertEqualObjects([failover currentHost], kPrimary);

    // 6. Probe succeeds, back to primary
    [failover reportSuccess];
    XCTAssertEqualObjects([failover currentHost], kPrimary);
}

- (void)test_failoverToSecondFallbackThenRecover {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1, kFallback2]];

    // Fail through to fallback2
    [failover reportFailure]; // -> fallback1
    [failover reportFailure]; // -> fallback2
    XCTAssertEqualObjects([failover currentHost], kFallback2);

    // Backoff elapses, probe primary, succeeds
    [failover setValue:[NSDate dateWithTimeIntervalSinceNow:-60] forKey:@"lastFailureTime"];
    XCTAssertEqualObjects([failover currentHost], kPrimary);
    [failover reportSuccess];

    // Fully recovered
    XCTAssertEqualObjects([failover currentHost], kPrimary);
}

- (void)test_reportFailure_onLastHostReturnsFalseRepeatedly {
    RadarHostFailover *failover = [[RadarHostFailover alloc] initWithHosts:@[kPrimary, kFallback1]];
    [failover reportFailure]; // -> fallback1
    BOOL result1 = [failover reportFailure]; // already on last host
    BOOL result2 = [failover reportFailure]; // still on last host
    XCTAssertFalse(result1);
    XCTAssertFalse(result2);
}

@end
