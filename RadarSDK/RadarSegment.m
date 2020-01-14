//
//  RadarRegion.m
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import "RadarSegment+Internal.h"

@implementation RadarSegment

- (instancetype)initWithDescription:(nonnull NSString *)description
                         externalId:(nonnull NSString *)externalId {
    self = [super init];
    if (self) {
        __description = description;
        _externalId = externalId;
    }
    return self;
}

- (nullable instancetype)initWithObject:(nullable id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *segmentDict = (NSDictionary *)object;

    NSString *description = @"";
    NSString *externalId = @"";
    
    id segmentDescriptionObj = segmentDict[@"description"];
    if ([segmentDescriptionObj isKindOfClass:[NSString class]]) {
        description = (NSString *)segmentDescriptionObj;
    }

    id segmentExternalIdObj = segmentDict[@"externalId"];
    if ([segmentExternalIdObj isKindOfClass:[NSString class]]) {
        externalId = (NSString *)segmentExternalIdObj;
    }
    
    return [[RadarSegment alloc] initWithDescription:description externalId:externalId];
}

@end
