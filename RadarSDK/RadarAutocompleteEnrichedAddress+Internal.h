//
//  RadarAutocompleteEnrichedAddress+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

// Redeclares the internal Swift initializer, the way RadarAddress+Internal.h does, so
// RadarAPIClient can build one from a response without the initializer going public.
@interface RadarAutocompleteEnrichedAddress ()

- (instancetype _Nullable)initWithObject:(id _Nullable)object;

@end
