//
//  RadarAPIHelper.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIHelper.h"

#import "RadarLogger.h"
#import "RadarSettings.h"

@implementation RadarAPIHelper

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *)headers
                   params:(NSDictionary *)params
        completionHandler:(RadarAPICompletionHandler)completionHandler {
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    req.HTTPMethod = method;
    
    if (headers) {
        for (NSString *key in headers) {
            NSString *value = [headers valueForKey:key];
            [req addValue:value forHTTPHeaderField:key];
        }
    }
    
    if (params) {
        [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:0 error:NULL]];
    }
    
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"API request | method = %@; url = %@; params = %@", method, url, params]];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 10;
    configuration.timeoutIntervalForResource = 10;

    NSURLSessionDataTask *task = [[NSURLSession sessionWithConfiguration:configuration] dataTaskWithRequest:req completionHandler:^void(NSData *data, NSURLResponse *response, NSError *error) {
       if (error) {
           [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"API error | error = %@", error]];
           
           return completionHandler(RadarStatusErrorNetwork, nil);
       }
       
       NSError *deserializationError = nil;
       id resObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
       if (deserializationError || ![resObj isKindOfClass:[NSDictionary class]]) {
           return completionHandler(RadarStatusErrorServer, nil);
       }
       
       NSDictionary *res = (NSDictionary *)resObj;
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"API response | url = %@; res = %@", url, res]];
       
       if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
           NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
           if (statusCode >= 200 && statusCode < 400) {
               return completionHandler(RadarStatusSuccess, res);
           } else if (statusCode == 400) {
               return completionHandler(RadarStatusErrorBadRequest, nil);
           } else if (statusCode == 401) {
               return completionHandler(RadarStatusErrorUnauthorized, nil);
           } else if (statusCode == 403) {
               return completionHandler(RadarStatusErrorForbidden, nil);
           } else if (statusCode == 429) {
               return completionHandler(RadarStatusErrorRateLimit, nil);
           } else if (statusCode >= 500 && statusCode <= 599) {
               return completionHandler(RadarStatusErrorServer, nil);
           }
       }
       
        completionHandler(RadarStatusErrorUnknown, nil);
    }];

    [task resume];
}

@end
