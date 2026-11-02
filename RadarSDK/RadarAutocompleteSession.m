//
//  RadarAutocompleteSession.m
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarAutocompleteSession.h"

#import "RadarAPIClient.h"
#import "RadarLogger.h"
#import "RadarUtils.h"

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@implementation RadarAutocompleteSession

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionToken = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype _Nullable)initWithSessionToken:(NSString *_Nonnull)sessionToken {
    if (![[NSUUID alloc] initWithUUIDString:sessionToken]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError type:RadarLogTypeSDKError message:@"Autocomplete sessionToken must be a UUID"];

        return nil;
    }

    self = [super init];
    if (self) {
        _sessionToken = [sessionToken copy];
    }
    return self;
}

- (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray<NSString *> *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
                 mailable:(BOOL)mailable
        completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"autocomplete()"];
    [[RadarAPIClient sharedInstance] autocompleteQuery:query
                                                  near:near
                                                layers:layers
                                                 limit:limit
                                               country:country
                                              mailable:mailable
                                          sessionToken:self.sessionToken
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                         if (completionHandler) {
                                             [RadarUtilsDeprecated runOnMainThread:^{
                                                 completionHandler(status, addresses);
                                             }];
                                         }
                                     }];
}

- (void)selectAddress:(RadarAddress *_Nonnull)address completionHandler:(RadarAutocompleteSelectCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"selectAddress()"];
    [[RadarAPIClient sharedInstance] selectAutocompleteAddress:address
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarAutocompleteEnrichedAddress *_Nullable enrichedAddress) {
                                                 if (completionHandler) {
                                                     [RadarUtilsDeprecated runOnMainThread:^{
                                                         completionHandler(status, enrichedAddress);
                                                     }];
                                                 }
                                             }];
}

@end
