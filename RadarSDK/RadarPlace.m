//
//  RadarPlace.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarChain+Internal.h"
#import "RadarCoordinate+Internal.h"
#import "RadarPlace+Internal.h"

@implementation RadarPlace

+ (NSArray<RadarPlace *> *_Nullable)placesFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *placesArr = (NSArray *)object;
    NSMutableArray<RadarPlace *> *mutablePlaces = [NSMutableArray<RadarPlace *> new];

    for (id placeObj in placesArr) {
        RadarPlace *place = [[RadarPlace alloc] initWithObject:placeObj];
        if (!place) {
            return nil;
        }
        [mutablePlaces addObject:place];
    }

    return mutablePlaces;
}

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

- (instancetype _Nullable)initWithObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id;
    NSString *name;
    NSArray<NSString *> *categories = @[];
    RadarChain *chain;
    RadarCoordinate *location = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)];
    NSString *group;
    NSDictionary *metadata;

    id idObj = dict[@"_id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id nameObj = dict[@"name"];
    if (nameObj && [nameObj isKindOfClass:[NSString class]]) {
        name = (NSString *)nameObj;
    }

    id categoriesObj = dict[@"categories"];
    if (categoriesObj && [categoriesObj isKindOfClass:[NSArray class]]) {
        categories = (NSArray *)categoriesObj;
    }

    id chainObj = dict[@"chain"];
    chain = [[RadarChain alloc] initWithObject:chainObj];

    id locationObj = dict[@"location"];
    if (locationObj && [locationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *locationDict = (NSDictionary *)locationObj;

        id locationCoordinatesObj = locationDict[@"coordinates"];
        if (!locationCoordinatesObj || ![locationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }

        NSArray *locationCoordinatesArr = (NSArray *)locationCoordinatesObj;
        if (locationCoordinatesArr.count != 2) {
            return nil;
        }

        id locationCoordinatesLongitudeObj = locationCoordinatesArr[0];
        id locationCoordinatesLatitudeObj = locationCoordinatesArr[1];
        if (!locationCoordinatesLongitudeObj || !locationCoordinatesLatitudeObj || ![locationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] ||
            ![locationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        NSNumber *locationCoordinatesLongitudeNumber = (NSNumber *)locationCoordinatesLongitudeObj;
        NSNumber *locationCoordinatesLatitudeNumber = (NSNumber *)locationCoordinatesLatitudeObj;

        float locationCoordinatesLongitudeFloat = [locationCoordinatesLongitudeNumber floatValue];
        float locationCoordinatesLatitudeFloat = [locationCoordinatesLatitudeNumber floatValue];

        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(locationCoordinatesLatitudeFloat, locationCoordinatesLongitudeFloat);
        location = [[RadarCoordinate alloc] initWithCoordinate:coordinate];
    }

    id groupObj = dict[@"group"];
    if ([groupObj isKindOfClass:[NSString class]]) {
        group = (NSString *)groupObj;
    }

    id metadataObj = dict[@"metadata"];
    if ([metadataObj isKindOfClass:[NSDictionary class]]) {
        metadata = (NSDictionary *)metadataObj;
    }

    if (_id && name) {
        return [[RadarPlace alloc] initWithId:_id name:name categories:categories chain:chain location:location group:group metadata:metadata];
    }

    return nil;
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

+ (NSArray<NSDictionary *> *)arrayForPlaces:(NSArray<RadarPlace *> *)places {
    if (!places) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:places.count];
    for (RadarPlace *place in places) {
        NSDictionary *dict = [place dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
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

@end
