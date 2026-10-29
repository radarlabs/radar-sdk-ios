//
//  RadarAutocompleteEnrichedAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// One header for all three types: they are parsed together out of a single /select payload.

#import <Foundation/Foundation.h>

#import "RadarAddressLocationDetails.h"
#import "RadarAddressPlace.h"
#import "RadarAutocompleteEnrichedAddress.h"

@interface RadarAddressPlace ()

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end

@interface RadarAddressLocationDetails ()

- (instancetype _Nullable)initWithObject:(id _Nullable)object;

@end

@interface RadarAutocompleteEnrichedAddress ()

- (instancetype _Nullable)initWithObject:(id _Nullable)object;

@end
