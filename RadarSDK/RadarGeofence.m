//
//  RadarGeofence.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarGeofence+Internal.h"
#import "RadarCircleGeometry+Internal.h"
#import "RadarPolygonGeometry+Internal.h"
#import "RadarCoordinate+Internal.h"

@implementation RadarGeofence

+ (NSArray<RadarGeofence *> * _Nullable)geofencesFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *geofencesArr = (NSArray *)object;
    NSMutableArray<RadarGeofence *> *mutableGeofences = [NSMutableArray<RadarGeofence *> new];

    for (id geofenceObj in geofencesArr) {
        RadarGeofence *geofence = [[RadarGeofence alloc] initWithObject:geofenceObj];
        if (!geofence) {
            return nil;
        }
        [mutableGeofences addObject:geofence];
    }

    return mutableGeofences;
}

- (instancetype _Nullable)initWithId:(NSString *)_id description:(NSString *)description tag:(NSString *)tag externalId:(NSString * _Nullable)externalId metadata:(NSDictionary * _Nullable)metadata geometry:(RadarGeofenceGeometry * _Nonnull)geometry {
    self = [super init];
    if (self) {
        __id = _id;
        __description = description;
        _tag = tag;
        _externalId = externalId;
        _metadata = metadata;
        _geometry = geometry;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(id)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *geofenceDict = (NSDictionary *)object;
    
    NSString *geofenceId;
    NSString *geofenceDescription;
    NSString *geofenceTag;
    NSString *geofenceExternalId;
    NSDictionary *geofenceMetadata;
    RadarGeofenceGeometry *geometry = [[RadarPolygonGeometry alloc] initWithCoordinates:@[]];
    
    id geofenceIdObj = geofenceDict[@"_id"];
    if (geofenceIdObj && [geofenceIdObj isKindOfClass:[NSString class]]) {
        geofenceId = (NSString *)geofenceIdObj;
    }
    
    id geofenceDescriptionObj = geofenceDict[@"description"];
    if (geofenceDescriptionObj && [geofenceDescriptionObj isKindOfClass:[NSString class]]) {
        geofenceDescription = (NSString *)geofenceDescriptionObj;
    }
    
    id geofenceTagObj = geofenceDict[@"tag"];
    if (geofenceTagObj && [geofenceTagObj isKindOfClass:[NSString class]]) {
        geofenceTag = (NSString *)geofenceTagObj;
    }
    
    id geofenceExternalIdObj = geofenceDict[@"externalId"];
    if (geofenceExternalIdObj && [geofenceExternalIdObj isKindOfClass:[NSString class]]) {
        geofenceExternalId = (NSString *)geofenceExternalIdObj;
    }
    
    id geofenceMetadataObj = geofenceDict[@"metadata"];
    if (geofenceMetadataObj && [geofenceMetadataObj isKindOfClass:[NSDictionary class]]) {
        geofenceMetadata = (NSDictionary *)geofenceMetadataObj;
    }
    
    id geometryTypeObj = geofenceDict[@"type"];
    if ([geometryTypeObj isKindOfClass:[NSString class]]) {
        NSString *type = (NSString *)geometryTypeObj;
        if ([type isEqualToString:@"circle"]) {
            id radiusObj = geofenceDict[@"geometryRadius"];
            id centerObj = geofenceDict[@"geometryCenter"];
            
            if (![radiusObj isKindOfClass:[NSNumber class]] || ![centerObj isKindOfClass:[NSDictionary class]]) {
                return nil;
            }
            
            id coordsObj = ((NSDictionary *) centerObj)[@"coordinates"];
            if (![coordsObj isKindOfClass:[NSArray class]]) {
                return nil;
            }
            
            NSArray *coordsArray = (NSArray *)coordsObj;
            if (coordsArray.count != 2) {
                return nil;
            }
            
            id longitudeObj = coordsArray[0];
            id latitudeObj = coordsArray[1];
            if (![longitudeObj isKindOfClass:[NSNumber class]] || ![latitudeObj isKindOfClass:[NSNumber class]]) {
                return nil;
            }
            
            float longitude = [((NSNumber *)longitudeObj) floatValue];
            float latitude = [((NSNumber *)latitudeObj) floatValue];
            float radius = [((NSNumber *)radiusObj) floatValue];
            
            RadarCoordinate *coord = [[RadarCoordinate alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
            geometry = [[RadarCircleGeometry alloc] initWithCenter:coord radius:radius];
            
        } else if ([type isEqualToString:@"polygon"]) {
            id polyObj = geofenceDict[@"geometry"];
            
            if (![polyObj isKindOfClass:[NSDictionary class]]) {
                return nil;
            }
            
            id coordsObj = ((NSDictionary *) polyObj)[@"coordinates"];
            if (![coordsObj isKindOfClass:[NSArray class]]) {
                return nil;
            }
            
            NSArray *coordsArray = (NSArray *)coordsObj;
            if (coordsArray.count != 1) {
                return nil;
            }
            
            id innerObj = coordsArray[0];
            if (![innerObj isKindOfClass:[NSArray class]]) {
                return nil;
            }
            
            NSArray *innerArray = (NSArray *)innerObj;
            NSMutableArray<RadarCoordinate *> *vertices = [NSMutableArray arrayWithCapacity:innerArray.count];
            for (uint i = 0; i < innerArray.count; i++) {
                id coordObj = innerArray[i];
                
                if (![coordObj isKindOfClass:[NSArray class]]) {
                    return nil;
                }
                NSArray *coordArray = (NSArray *)coordObj;
                if (coordArray.count != 2) {
                    return nil;
                }
                
                id longitudeObj = coordArray[0];
                id latitudeObj = coordArray[1];
                if (![longitudeObj isKindOfClass:[NSNumber class]] || ![latitudeObj isKindOfClass:[NSNumber class]]) {
                    return nil;
                }
                
                float longitude = [((NSNumber *)longitudeObj) floatValue];
                float latitude = [((NSNumber *)latitudeObj) floatValue];
                
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
                vertices[i] = [[RadarCoordinate alloc] initWithCoordinate:coord];
            }
            
            geometry = [[RadarPolygonGeometry alloc] initWithCoordinates:vertices];
        }
    }
    
    if (geofenceId && geofenceDescription) {
        return [[RadarGeofence alloc] initWithId:geofenceId description:geofenceDescription tag:geofenceTag externalId:geofenceExternalId metadata:geofenceMetadata geometry:geometry];
    }
    
    return nil;
}

@end
