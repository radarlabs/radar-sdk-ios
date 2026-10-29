//
//  RadarAutocompleteEnrichedAddress.m
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarAutocompleteEnrichedAddress+Internal.h"

@implementation RadarAutocompleteEnrichedAddress

- (instancetype _Nullable)initWithObject:(id _Nullable)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    self = [super init];
    if (self) {
        id formattedAddressObj = dict[@"formattedAddress"];
        if ([formattedAddressObj isKindOfClass:[NSString class]]) {
            _formattedAddress = (NSString *)formattedAddressObj;
        }

        _locationDetails = [[RadarAddressLocationDetails alloc] initWithObject:dict[@"locationDetails"]];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self.formattedAddress forKey:@"formattedAddress"];
    [dict setValue:[self.locationDetails dictionaryValue] forKey:@"locationDetails"];
    return dict;
}

@end
