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

NS_ASSUME_NONNULL_BEGIN

/**
 Called when an autocomplete selection report succeeds, fails, or times out.

 Receives the request status and, for projects with address enrichment enabled, the enriched address. For every
 other project the address is nil on success: the selection was recorded and the server returned no body.

 @see https://radar.com/documentation/api#autocomplete
 */
typedef void (^_Nullable RadarAutocompleteSelectCompletionHandler)(RadarStatus status, RadarAddress *_Nullable address);

/**
 One autocomplete session: a single search field and the selection the user makes in it.

 Create one per address field. Two fields sharing a session also share the server's per-session selection cap
 and its enrichment snapshot window, so typing into one can stop the other's results from enriching — a
 checkout with a billing and a shipping address wants two sessions, not one.

 The session mints and owns its token, so there is no token for a caller to get wrong. It stays valid as long
 as the field is in use; the server expires a session after 20 minutes of inactivity, and the next call through
 this instance simply opens a fresh one.

 @see https://radar.com/documentation/api#autocomplete
 */
@interface RadarAutocompleteSession : NSObject

/**
 The token this session sends, exposed for correlating with your own analytics.
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
 @param completionHandler A completion handler. Each address carries the handle `selectAddress:completionHandler:` needs.

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

 Pass the address straight back from this session's `autocompleteQuery:`; it carries the opaque handle the API
 needs. An address from anywhere else carries none, so nothing is reported, no request is made, and the
 completion handler receives `RadarStatusErrorBadRequest`.

 @param address The selected address, as returned by this session's `autocompleteQuery:`.
 @param completionHandler An optional completion handler.

 @see https://radar.com/documentation/api#autocomplete
 */
- (void)selectAddress:(RadarAddress *_Nonnull)address
    completionHandler:(RadarAutocompleteSelectCompletionHandler)completionHandler NS_SWIFT_NAME(select(address:completionHandler:));

@end

NS_ASSUME_NONNULL_END
