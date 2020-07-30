//
//  RadarPlace.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarChain+Internal.h"
#import "RadarCollectionAdditions.h"
#import "RadarCoordinate+Internal.h"
#import "RadarJSONCoding.h"
#import "RadarPlace+Internal.h"

@implementation RadarPlace

- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                                name:(NSString *_Nonnull)name
                          categories:(NSArray<NSString *> *_Nullable)categories
                               chain:(RadarChain *_Nullable)chain
                            location:(RadarCoordinate *_Nonnull)location
                               group:(NSString *_Nonnull)group
                            metadata:(NSDictionary *)metadata {
    self = [super init];
    if (self) {
        __id = _id;
        _name = name;
        _categories = categories;
        _chain = chain;
        _location = location;
        _group = group;
        _metadata = metadata;
    }
    return self;
}

#pragma mark - JSON coding

+ (NSArray<RadarPlace *> *_Nullable)placesFromObject:(id _Nonnull)object {
    FROM_JSON_ARRAY_DEFAULT_IMP(object, RadarPlace);
}

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id = [dict radar_stringForKey:@"_id"];
    NSString *name = [dict radar_stringForKey:@"name"];
    NSArray<NSString *> *categories = [dict radar_arrayForKey:@"categories"];
    RadarChain *chain = [[RadarChain alloc] initWithObject:dict[@"chain"]];
    RadarCoordinate *location = [[RadarCoordinate alloc] initWithObject:dict[@"location"]];
    NSString *group = [dict radar_stringForKey:@"group"];
    NSDictionary *metadata = [dict radar_dictionaryForKey:@"metadata"];

    if (_id && name && categories && location) {
        return [[RadarPlace alloc] initWithId:_id name:name categories:categories chain:chain location:location group:group metadata:metadata];
    }

    return nil;
}

+ (NSArray<NSDictionary *> *)arrayForPlaces:(NSArray<RadarPlace *> *)places {
    TO_JSON_ARRAY_DEFAULT_IMP(places, RadarPlace);
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.name forKey:@"name"];
    [dict setValue:self.categories forKey:@"categories"];
    if (self.chain) {
        NSDictionary *chainDict = [self.chain dictionaryValue];
        [dict setValue:chainDict forKey:@"chain"];
    }
    [dict setValue:self.group forKey:@"group"];
    [dict setValue:self.metadata forKey:@"metadata"];
    return dict;
}

- (BOOL)isChain:(NSString *)slug {
    if (!self.chain || !self.chain.slug) {
        return NO;
    }

    return [self.chain.slug isEqualToString:slug];
}

- (BOOL)hasCategory:(NSString *)category {
    if (!self.categories) {
        return NO;
    }

    for (unsigned int i = 0; i < self.categories.count; i++) {
        if ([self.categories[i] isEqualToString:category]) {
            return YES;
        }
    }

    return NO;
}

@end
