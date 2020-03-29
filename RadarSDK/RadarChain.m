//
//  RadarChain.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarChain.h"

@implementation RadarChain

- (instancetype _Nullable)initWithSlug:(NSString *_Nonnull)slug
                                  name:(NSString *_Nonnull)name
                            externalId:(NSString *_Nullable)externalId
                              metadata:(nullable NSDictionary *)metadata {
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

    NSDictionary *dict = (NSDictionary *)object;

    NSString *slug;
    NSString *name;
    NSString *externalId;
    NSDictionary *metadata;

    id slugObj = dict[@"slug"];
    if (slugObj && [slugObj isKindOfClass:[NSString class]]) {
        slug = (NSString *)slugObj;
    }

    id nameObj = dict[@"name"];
    if (nameObj && [nameObj isKindOfClass:[NSString class]]) {
        name = (NSString *)nameObj;
    }

    id externalIdObj = dict[@"externalId"];
    if ([externalIdObj isKindOfClass:[NSString class]]) {
        externalId = (NSString *)externalIdObj;
    }

    id metadataObj = dict[@"metadata"];
    if ([metadataObj isKindOfClass:[NSDictionary class]]) {
        metadata = (NSDictionary *)metadataObj;
    }

    if (slug && name) {
        return [[RadarChain alloc] initWithSlug:slug name:name externalId:externalId metadata:metadata];
    }

    return nil;
}

+ (NSArray<NSDictionary *> *)arrayForChains:(NSArray<RadarChain *> *)chains {
    if (!chains) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:chains.count];
    for (RadarChain *chain in chains) {
        NSDictionary *dict = [chain dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self.slug forKey:@"slug"];
    [dict setValue:self.name forKey:@"name"];
    [dict setValue:self.externalId forKey:@"externalId"];
    [dict setValue:self.metadata forKey:@"metadata"];
    return dict;
}

@end
