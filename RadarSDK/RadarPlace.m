//
//  RadarPlace.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPlace+Internal.h"
#import "RadarChain+Internal.h"
#import "RadarCoordinate+Internal.h"

@implementation RadarPlace

+ (NSArray<RadarPlace *> * _Nullable)placesFromObject:(id _Nonnull)object {
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


- (instancetype _Nullable)initWithId:(NSString * _Nonnull)_id name:(NSString * _Nonnull)name categories:(NSArray<NSString *> * _Nullable)categories chain:(RadarChain *_Nullable)chain location:(RadarCoordinate * _Nonnull)location group:(NSString * _Nonnull)group metadata:(NSDictionary *)metadata {
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
    
    NSDictionary *placeDict = (NSDictionary *)object;
    
    NSString *placeId;
    NSString *placeName;
    NSArray<NSString *> *placeCategories = @[];
    RadarChain *placeChain;
    RadarCoordinate *placeLocation = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)];
    NSString *placeGroup;
    NSDictionary *placeMetadata;
    
    id placeIdObj = placeDict[@"_id"];
    if (placeIdObj && [placeIdObj isKindOfClass:[NSString class]]) {
        placeId = (NSString *)placeIdObj;
    }
    
    id placeNameObj = placeDict[@"name"];
    if (placeNameObj && [placeNameObj isKindOfClass:[NSString class]]) {
        placeName = (NSString *)placeNameObj;
    }
    
    id placeCategoriesObj = placeDict[@"categories"];
    if (placeCategoriesObj && [placeCategoriesObj isKindOfClass:[NSArray class]]) {
        placeCategories = (NSArray *)placeCategoriesObj;
    }
    
    id placeChainObj = placeDict[@"chain"];
    placeChain = [[RadarChain alloc] initWithObject:placeChainObj];
    
    id placeLocationObj = placeDict[@"location"];
    if (placeLocationObj && [placeLocationObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *placeLocationDict = (NSDictionary *)placeLocationObj;
        
        id placeLocationCoordinatesObj = placeLocationDict[@"coordinates"];
        if (!placeLocationCoordinatesObj || ![placeLocationCoordinatesObj isKindOfClass:[NSArray class]]) {
            return nil;
        }
        
        NSArray *placeLocationCoordinatesArr = (NSArray *)placeLocationCoordinatesObj;
        if (placeLocationCoordinatesArr.count != 2) {
            return nil;
        }
        
        id placeLocationCoordinatesLongitudeObj = placeLocationCoordinatesArr[0];
        id placeLocationCoordinatesLatitudeObj = placeLocationCoordinatesArr[1];
        if (!placeLocationCoordinatesLongitudeObj || !placeLocationCoordinatesLatitudeObj || ![placeLocationCoordinatesLongitudeObj isKindOfClass:[NSNumber class]] || ![placeLocationCoordinatesLatitudeObj isKindOfClass:[NSNumber class]]) {
            return nil;
        }
        
        NSNumber *placeLocationCoordinatesLongitudeNumber = (NSNumber *)placeLocationCoordinatesLongitudeObj;
        NSNumber *placeLocationCoordinatesLatitudeNumber = (NSNumber *)placeLocationCoordinatesLatitudeObj;
        
        float placeLocationCoordinatesLongitudeFloat = [placeLocationCoordinatesLongitudeNumber floatValue];
        float placeLocationCoordinatesLatitudeFloat = [placeLocationCoordinatesLatitudeNumber floatValue];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(placeLocationCoordinatesLatitudeFloat, placeLocationCoordinatesLongitudeFloat);
        placeLocation = [[RadarCoordinate alloc] initWithCoordinate:coordinate];
    }
    
    id placeGroupObj = placeDict[@"group"];
    if ([placeGroupObj isKindOfClass:[NSString class]]) {
        placeGroup = (NSString *)placeGroupObj;
    }
    
    id placeMetadataObj = placeDict[@"metadata"];
    if ([placeMetadataObj isKindOfClass:[NSDictionary class]]) {
        placeMetadata = (NSDictionary *)placeMetadataObj;
    }
    
    if (placeId && placeName) {
        return [[RadarPlace alloc] initWithId:placeId name:placeName categories:placeCategories chain:placeChain location:placeLocation group:placeGroup metadata:placeMetadata];
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
        NSDictionary *dict = [place toDictionary];
        [arr addObject:dict];
    }
    return arr;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"_id"];
    [dict setValue:self.name forKey:@"name"];
    if (self.categories && self.categories.count) {
        [dict setValue:self.categories forKey:@"categories"];
    }
    if (self.chain) {
      NSDictionary *chain = @{
          @"slug": self.chain.slug,
          @"name": self.chain.name
      };
      [dict setValue:chain forKey:@"chain"];
    }
    return dict;
}

@end
