//
//  RadarChain.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarChain.h"
#import "RadarChain+Internal.h"
#import "RadarCollectionAdditions.h"
#import "RadarJSONCoding.h"

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

#pragma mark - JSON coding

+ (NSArray<RadarChain *> *_Nullable)chainsFromObject:(id)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarChain);
}

- (instancetype _Nullable)initWithObject:(id _Nullable)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *slug = [dict radar_stringForKey:@"slug"];
    NSString *name = [dict radar_stringForKey:@"name"];
    NSString *externalId = [dict radar_stringForKey:@"externalId"];
    NSDictionary *metadata = [dict radar_dictionaryForKey:@"metadata"];

    if (slug && name) {
        return [[RadarChain alloc] initWithSlug:slug name:name externalId:externalId metadata:metadata];
    }

    return nil;
}

+ (NSArray<NSDictionary *> *)arrayForChains:(NSArray<RadarChain *> *)chains {
    TO_JSON_ARRAY_DEFAULT_IMP(chains, RadarChain);
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
