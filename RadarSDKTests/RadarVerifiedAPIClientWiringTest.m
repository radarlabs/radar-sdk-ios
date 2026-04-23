//
//  RadarVerifiedAPIClientWiringTest.m
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../RadarSDK/RadarAPIClient.h"
#import "../RadarSDK/RadarSettings.h"
#import "../RadarSDK/RadarFailoverAPICoordinator.h"
#import "RadarAPIHelperMock.h"

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

// Class name is prefixed `RadarVerified*` (not `RadarAPIClient*`) so XCTest
// orders this class after RadarSDKTests — which has a `+setUp` that asserts
// Radar has not yet been initialized.

/// Proves that the verified branches of RadarAPIClient actually route
/// through RadarFailoverAPICoordinator — a pure-unit test of the
/// coordinator can't catch a regression where someone rewires
/// RadarAPIClient to call RadarAPIHelper directly again.
@interface RadarVerifiedAPIClientWiringTest : XCTestCase
@property (nonnull, strong, nonatomic) RadarAPIHelperMock *apiHelperMock;
@end

@implementation RadarVerifiedAPIClientWiringTest

- (void)setUp {
    [super setUp];
    [Radar initializeWithPublishableKey:@"prj_test_pk_0000000000000000"];
    self.apiHelperMock = [RadarAPIHelperMock new];
    [RadarAPIClient sharedInstance].apiHelper = self.apiHelperMock;
}

- (void)test_verifiedGetConfig_failsOverToSecondary {
    // Primary returns a response that doesn't look like it came from Radar
    // (no top-level `meta`). The coordinator should retry on the secondary
    // host. Secondary returns the same shape — coordinator then surfaces
    // the error. We only care that `lastUrl` ended up pointing at the
    // secondary host, which can only happen if the coordinator is in the
    // path.
    self.apiHelperMock.mockStatus = RadarStatusErrorServer;
    self.apiHelperMock.mockResponse = @{@"error": @"cloudflare"};

    XCTestExpectation *expectation = [self expectationWithDescription:@"config callback"];
    [[RadarAPIClient sharedInstance] getConfigForUsage:@"wiring-test"
                                              verified:YES
                                     completionHandler:^(RadarStatus status, RadarConfig *config) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];

    XCTAssertNotNil(self.apiHelperMock.lastUrl);
    XCTAssertTrue([self.apiHelperMock.lastUrl containsString:@"api-verified-cf.use1.radar-staging.com"],
                  @"expected lastUrl to be on the secondary host after failover, got: %@",
                  self.apiHelperMock.lastUrl);
}

@end
