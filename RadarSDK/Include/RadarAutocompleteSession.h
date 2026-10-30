//
//  RadarAutocompleteSession.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarAddress.h"
#import "RadarAutocompleteEnrichedAddress.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Called when an autocomplete selection report succeeds, fails, or times out.

 Receives the request status and, where available, the enriched address.

 @see https://radar.com/documentation/api#autocomplete
 */
typedef void (^_Nullable RadarAutocompleteSelectCompletionHandler)(RadarStatus status, RadarAutocompleteEnrichedAddress *_Nullable address);

/**
 An autocomplete search field and the selection a user makes in it.

 Create one session per address field.

 @see https://radar.com/documentation/api#autocomplete
 */
@interface RadarAutocompleteSession : NSObject

/**
 The token this session sends.
 */
@property (copy, nonatomic, readonly) NSString *sessionToken;

/**
 Autocompletes partial addresses and place names within this session, sorted by relevance.

 @param query The partial address or place name to autocomplete.
 @param near A location for the search.
 @param layers Optional layer filters.
 @param limit The max number of addresses to return. A number between 1 and 100.
 @param country An optional country filter. A string, the unique 2-letter country code.
 @param mailable Whether to only include mailable addresses.
 @param completionHandler A completion handler.

 @see https://radar.com/documentation/api#autocomplete
 */
- (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray<NSString *> *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
                 mailable:(BOOL)mailable
        completionHandler:(RadarGeocodeCompletionHandler)completionHandler NS_SWIFT_NAME(autocomplete(query:near:layers:limit:country:mailable:completionHandler:));

/**
 Reports which result the user chose, and returns it enriched where available.

 @param address The selected result, as returned by this session's `autocompleteQuery:`. An address from
 anywhere else fails with `RadarStatusErrorBadRequest` and makes no request.
 @param completionHandler An optional completion handler.

 @see https://radar.com/documentation/api#autocomplete
 */
- (void)selectAddress:(RadarAddress *_Nonnull)address
    completionHandler:(RadarAutocompleteSelectCompletionHandler)completionHandler NS_SWIFT_NAME(select(address:completionHandler:));

@end

NS_ASSUME_NONNULL_END
