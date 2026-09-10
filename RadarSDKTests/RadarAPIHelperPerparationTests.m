//
//  RadarAPIHelperPerparationTests.m
//  RadarSDK
//
//  Created by Alan Charles on 9/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../RadarSDK/RadarAPIHelper.h"

// Intercepts requests from this test's session; nothing reaches the network.
@interface RadarPreparationTestProtocol : NSURLProtocol
@end

@implementation RadarPreparationTestProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSString *attempt = [self.request valueForHTTPHeaderField:@"X-Test-Attempt"];

    if ([attempt isEqualToString:@"1"]) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:NSURLErrorNetworkConnectionLost
                                        userInfo:nil];
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }

    XCTAssertEqualObjects(attempt, @"2");

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
        initWithURL:self.request.URL
        statusCode:200
        HTTPVersion:@"HTTP/1.1"
        headerFields:@{@"Content-Type": @"application/json"}];

    [self.client URLProtocol:self
         didReceiveResponse:response
         cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    NSData *data = [@"{\"ok\":true}" dataUsingEncoding:NSUTF8StringEncoding];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {}

@end

@interface RadarAPIHelperPreparationTests : XCTestCase
@end

@implementation RadarAPIHelperPreparationTests

- (void)testLostConnectionPreparesEachAttempt {
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.protocolClasses = @[[RadarPreparationTestProtocol class]];

    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:configuration];

    RadarAPIHelper *helper = [[RadarAPIHelper alloc] init];

    // Inject the test transport into the existing private session property.
    [helper setValue:session forKey:@"standardSession"];

    XCTestExpectation *finished =
        [self expectationWithDescription:@"Retry completes"];
    finished.assertForOverFulfill = YES;

    __block NSInteger preparationCount = 0;

    [helper requestWithMethod:@"POST"
                          url:@"https://retry-test.invalid/v1/track"
                      headers:@{@"Content-Type": @"application/json"}
                       params:@{@"installId": @"test-install"}
                        sleep:NO
                   logPayload:NO
              extendedTimeout:NO
               prepareRequest:^(NSURLRequest *request,
                                RadarRequestPreparationCompletion completion) {
        preparationCount += 1;

        // Every preparation must start from the original request.
        XCTAssertNil([request valueForHTTPHeaderField:@"X-Test-Attempt"]);
        XCTAssertEqualObjects(request.HTTPMethod, @"POST");

        NSMutableURLRequest *prepared = [request mutableCopy];
        [prepared setValue:[NSString stringWithFormat:@"%ld",
                            (long)preparationCount]
        forHTTPHeaderField:@"X-Test-Attempt"];

        completion(RadarStatusSuccess, prepared, nil);
    }
            completionHandler:^(RadarStatus status,
                                NSDictionary *response,
                                NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertEqual(status, RadarStatusSuccess);
        XCTAssertNil(error);
        XCTAssertEqualObjects(response[@"ok"], @YES);
        XCTAssertEqual(preparationCount, 2);
        [finished fulfill];
    }];

    [self waitForExpectations:@[finished] timeout:5.0];
    [session invalidateAndCancel];
}

- (void)testPreparationFailureReleasesSemaphore {
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.protocolClasses = @[[RadarPreparationTestProtocol class]];

    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:configuration];

    RadarAPIHelper *helper = [[RadarAPIHelper alloc] init];
    [helper setValue:session forKey:@"standardSession"];

    XCTestExpectation *first =
        [self expectationWithDescription:@"First preparation fails"];
    XCTestExpectation *second =
        [self expectationWithDescription:@"Next request also completes"];
    first.assertForOverFulfill = YES;
    second.assertForOverFulfill = YES;

    NSError *expectedError =
        [NSError errorWithDomain:@"RadarPreparationTest"
                            code:1
                        userInfo:nil];

    for (XCTestExpectation *finished in @[first, second]) {
        [helper requestWithMethod:@"POST"
                              url:@"https://retry-test.invalid/v1/track"
                          headers:@{}
                           params:@{}
                            sleep:YES
                       logPayload:NO
                  extendedTimeout:NO
                   prepareRequest:^(NSURLRequest *request,
                                    RadarRequestPreparationCompletion completion) {
            dispatch_async(
                dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0),
                ^{
                    completion(
                        RadarStatusErrorUnknown,
                        nil,
                        expectedError
                    );
                }
            );
        }
                completionHandler:^(RadarStatus status,
                                    NSDictionary *response,
                                    NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            XCTAssertEqual(status, RadarStatusErrorUnknown);
            XCTAssertNil(response);
            XCTAssertEqualObjects(error, expectedError);
            [finished fulfill];
        }];
    }

    [self waitForExpectations:@[first, second] timeout:5.0];
    [session invalidateAndCancel];
}

@end
