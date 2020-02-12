//
//  RadarChain.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarChain.h"

@implementation RadarChain

- (instancetype _Nullable)initWithSlug:(NSString * _Nonnull)slug name:(NSString * _Nonnull)name externalId:(NSString * _Nullable)externalId metadata:(nullable NSDictionary *)metadata {
    self = [super init];
    if (self) {
        _slug = slug;
        _name = name;
        _externalId = externalId;
        _metadata = metadata;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *chainDict = (NSDictionary *)object;
    
    NSString *chainSlug;
    NSString *chainName;
    NSString *chainExternalId;
    NSDictionary *chainMetadata;
    
    id chainSlugObj = chainDict[@"slug"];
    if (chainSlugObj && [chainSlugObj isKindOfClass:[NSString class]]) {
        chainSlug = (NSString *)chainSlugObj;
    }
    
    id chainNameObj = chainDict[@"name"];
    if (chainNameObj && [chainNameObj isKindOfClass:[NSString class]]) {
        chainName = (NSString *)chainNameObj;
    }
    
    id chainExternalIdObj = chainDict[@"externalId"];
    if ([chainExternalIdObj isKindOfClass:[NSString class]]) {
        chainExternalId = (NSString *)chainExternalIdObj;
    }
    
    id chainMetadataObj = chainDict[@"metadata"];
    if ([chainMetadataObj isKindOfClass:[NSDictionary class]]) {
        chainMetadata = (NSDictionary *)chainMetadataObj;
    }
    
    if (chainSlug && chainName) {
        return [[RadarChain alloc] initWithSlug:chainSlug name:chainName externalId:chainExternalId metadata:chainMetadata];
    }
    
    return nil;
}

@end
