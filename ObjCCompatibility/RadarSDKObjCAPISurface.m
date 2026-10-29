//
//  RadarSDKObjCAPISurface.m
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// objc-only: This file checks the Objective-C interface of SDK classes implemented in Swift, so it
// must stay Objective-C. Do not migrate it.
//
// Each function calls one public member the way an Objective-C app would. `make ci-build-example`
// compiles this file against the built framework with -Werror, so a Swift change that renames a
// selector or property, removes `@objc` from a member, or changes a type or nullability fails CI.
//
// The functions are never called. When a Swift class gains public members, add them here. When a
// change here is intentional, it is a breaking change for Objective-C apps: say so in the release notes.

@import RadarSDK;

#define RADAR_API_SURFACE __attribute__((unused)) static

#pragma mark - Radar

RADAR_API_SURFACE void call_Radar_class_startRangingBeacons(void) { [Radar startRangingBeacons]; }
RADAR_API_SURFACE void call_Radar_class_stopRangingBeacons(void) { [Radar stopRangingBeacons]; }

#pragma mark - RadarChain

RADAR_API_SURFACE Class class_RadarChain(void) { return [RadarChain class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarChain_slug(RadarChain *obj) { return obj.slug; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarChain_name(RadarChain *obj) { return obj.name; }
RADAR_API_SURFACE NSString *_Nullable get_RadarChain_externalId(RadarChain *obj) { return obj.externalId; }
RADAR_API_SURFACE NSDictionary *_Nullable get_RadarChain_metadata(RadarChain *obj) { return obj.metadata; }
RADAR_API_SURFACE NSArray<NSDictionary *> *_Nullable call_RadarChain_class_arrayForChains(NSArray<RadarChain *> *_Nullable a0) { return [RadarChain arrayForChains:a0]; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarChain_dictionaryValue(RadarChain *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarGeofenceGeometry

RADAR_API_SURFACE Class class_RadarGeofenceGeometry(void) { return [RadarGeofenceGeometry class]; }

#pragma mark - RadarCircleGeometry

RADAR_API_SURFACE Class class_RadarCircleGeometry(void) { return [RadarCircleGeometry class]; }
RADAR_API_SURFACE RadarCoordinate *_Nonnull get_RadarCircleGeometry_center(RadarCircleGeometry *obj) { return obj.center; }
RADAR_API_SURFACE double get_RadarCircleGeometry_radius(RadarCircleGeometry *obj) { return obj.radius; }

#pragma mark - RadarContext

RADAR_API_SURFACE Class class_RadarContext(void) { return [RadarContext class]; }
RADAR_API_SURFACE NSArray<RadarGeofence *> *_Nonnull get_RadarContext_geofences(RadarContext *obj) { return obj.geofences; }
RADAR_API_SURFACE RadarPlace *_Nullable get_RadarContext_place(RadarContext *obj) { return obj.place; }
RADAR_API_SURFACE RadarRegion *_Nullable get_RadarContext_country(RadarContext *obj) { return obj.country; }
RADAR_API_SURFACE RadarRegion *_Nullable get_RadarContext_state(RadarContext *obj) { return obj.state; }
RADAR_API_SURFACE RadarRegion *_Nullable get_RadarContext_dma(RadarContext *obj) { return obj.dma; }
RADAR_API_SURFACE RadarRegion *_Nullable get_RadarContext_postalCode(RadarContext *obj) { return obj.postalCode; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarContext_dictionaryValue(RadarContext *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarCoordinate

RADAR_API_SURFACE Class class_RadarCoordinate(void) { return [RadarCoordinate class]; }
RADAR_API_SURFACE CLLocationCoordinate2D get_RadarCoordinate_coordinate(RadarCoordinate *obj) { return obj.coordinate; }
RADAR_API_SURFACE RadarCoordinate *_Nullable call_RadarCoordinate_initWithCoordinate(CLLocationCoordinate2D a0) { return [[RadarCoordinate alloc] initWithCoordinate:a0]; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarCoordinate_dictionaryValue(RadarCoordinate *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarExpectedAddress

RADAR_API_SURFACE Class class_RadarExpectedAddress(void) { return [RadarExpectedAddress class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarExpectedAddress_expectedAddress(RadarExpectedAddress *obj) { return obj.expectedAddress; }
RADAR_API_SURFACE NSString *_Nullable get_RadarExpectedAddress_formattedAddress(RadarExpectedAddress *obj) { return obj.formattedAddress; }
RADAR_API_SURFACE NSNumber *_Nullable get_RadarExpectedAddress_latitude(RadarExpectedAddress *obj) { return obj.latitude; }
RADAR_API_SURFACE NSNumber *_Nullable get_RadarExpectedAddress_longitude(RadarExpectedAddress *obj) { return obj.longitude; }
RADAR_API_SURFACE BOOL get_RadarExpectedAddress_atAddress(RadarExpectedAddress *obj) { return obj.atAddress; }
RADAR_API_SURFACE enum RadarExpectedAddressConfidence get_RadarExpectedAddress_confidence(RadarExpectedAddress *obj) { return obj.confidence; }
RADAR_API_SURFACE NSNumber *_Nullable get_RadarExpectedAddress_distance(RadarExpectedAddress *obj) { return obj.distance; }
RADAR_API_SURFACE RadarExpectedAddress *_Nonnull call_RadarExpectedAddress_init(void) { return [[RadarExpectedAddress alloc] init]; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarExpectedAddress_dictionaryValue(RadarExpectedAddress *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarFraud

RADAR_API_SURFACE Class class_RadarFraud(void) { return [RadarFraud class]; }
RADAR_API_SURFACE BOOL get_RadarFraud_passed(RadarFraud *obj) { return obj.passed; }
RADAR_API_SURFACE BOOL get_RadarFraud_bypassed(RadarFraud *obj) { return obj.bypassed; }
RADAR_API_SURFACE BOOL get_RadarFraud_verified(RadarFraud *obj) { return obj.verified; }
RADAR_API_SURFACE BOOL get_RadarFraud_proxy(RadarFraud *obj) { return obj.proxy; }
RADAR_API_SURFACE BOOL get_RadarFraud_mocked(RadarFraud *obj) { return obj.mocked; }
RADAR_API_SURFACE BOOL get_RadarFraud_compromised(RadarFraud *obj) { return obj.compromised; }
RADAR_API_SURFACE BOOL get_RadarFraud_jumped(RadarFraud *obj) { return obj.jumped; }
RADAR_API_SURFACE BOOL get_RadarFraud_inaccurate(RadarFraud *obj) { return obj.inaccurate; }
RADAR_API_SURFACE BOOL get_RadarFraud_sharing(RadarFraud *obj) { return obj.sharing; }
RADAR_API_SURFACE BOOL get_RadarFraud_blocked(RadarFraud *obj) { return obj.blocked; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarFraud_dictionaryValue(RadarFraud *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarInitializeOptions

RADAR_API_SURFACE Class class_RadarInitializeOptions(void) { return [RadarInitializeOptions class]; }
RADAR_API_SURFACE BOOL get_RadarInitializeOptions_autoLogNotificationConversions(RadarInitializeOptions *obj) { return obj.autoLogNotificationConversions; }
RADAR_API_SURFACE void set_RadarInitializeOptions_autoLogNotificationConversions(RadarInitializeOptions *obj, BOOL value) { obj.autoLogNotificationConversions = value; }
RADAR_API_SURFACE BOOL get_RadarInitializeOptions_autoHandleNotificationDeepLinks(RadarInitializeOptions *obj) { return obj.autoHandleNotificationDeepLinks; }
RADAR_API_SURFACE void set_RadarInitializeOptions_autoHandleNotificationDeepLinks(RadarInitializeOptions *obj, BOOL value) { obj.autoHandleNotificationDeepLinks = value; }
RADAR_API_SURFACE BOOL get_RadarInitializeOptions_silentPush(RadarInitializeOptions *obj) { return obj.silentPush; }
RADAR_API_SURFACE void set_RadarInitializeOptions_silentPush(RadarInitializeOptions *obj, BOOL value) { obj.silentPush = value; }
RADAR_API_SURFACE BOOL get_RadarInitializeOptions_trackVerifiedAutoFailover(RadarInitializeOptions *obj) { return obj.trackVerifiedAutoFailover; }
RADAR_API_SURFACE void set_RadarInitializeOptions_trackVerifiedAutoFailover(RadarInitializeOptions *obj, BOOL value) { obj.trackVerifiedAutoFailover = value; }
RADAR_API_SURFACE NSTimeInterval get_RadarInitializeOptions_networkTimeoutInterval(RadarInitializeOptions *obj) { return obj.networkTimeoutInterval; }
RADAR_API_SURFACE void set_RadarInitializeOptions_networkTimeoutInterval(RadarInitializeOptions *obj, NSTimeInterval value) { obj.networkTimeoutInterval = value; }
RADAR_API_SURFACE NSTimeInterval get_RadarInitializeOptions_ipChangeDebounceInterval(RadarInitializeOptions *obj) { return obj.ipChangeDebounceInterval; }
RADAR_API_SURFACE void set_RadarInitializeOptions_ipChangeDebounceInterval(RadarInitializeOptions *obj, NSTimeInterval value) { obj.ipChangeDebounceInterval = value; }
RADAR_API_SURFACE RadarInitializeOptions *_Nonnull call_RadarInitializeOptions_init(void) { return [[RadarInitializeOptions alloc] init]; }
RADAR_API_SURFACE RadarInitializeOptions *_Nonnull call_RadarInitializeOptions_initWithDict(NSDictionary *_Nullable a0) { return [[RadarInitializeOptions alloc] initWithDict:a0]; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarInitializeOptions_dictionaryValue(RadarInitializeOptions *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarOperatingHours

RADAR_API_SURFACE Class class_RadarOperatingHours(void) { return [RadarOperatingHours class]; }
RADAR_API_SURFACE NSDictionary<NSString *, NSArray<NSArray<NSString *> *> *> *_Null_unspecified get_RadarOperatingHours_hours(RadarOperatingHours *obj) { return obj.hours; }

#pragma mark - RadarPolygonGeometry

RADAR_API_SURFACE Class class_RadarPolygonGeometry(void) { return [RadarPolygonGeometry class]; }
RADAR_API_SURFACE NSArray<RadarCoordinate *> *_Nullable get_RadarPolygonGeometry__coordinates(RadarPolygonGeometry *obj) { return obj._coordinates; }
RADAR_API_SURFACE RadarCoordinate *_Nonnull get_RadarPolygonGeometry_center(RadarPolygonGeometry *obj) { return obj.center; }
RADAR_API_SURFACE double get_RadarPolygonGeometry_radius(RadarPolygonGeometry *obj) { return obj.radius; }

#pragma mark - RadarRegion

RADAR_API_SURFACE Class class_RadarRegion(void) { return [RadarRegion class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRegion__id(RadarRegion *obj) { return obj._id; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRegion_name(RadarRegion *obj) { return obj.name; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRegion_code(RadarRegion *obj) { return obj.code; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRegion_type(RadarRegion *obj) { return obj.type; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRegion_flag(RadarRegion *obj) { return obj.flag; }
RADAR_API_SURFACE BOOL get_RadarRegion_allowed(RadarRegion *obj) { return obj.allowed; }
RADAR_API_SURFACE BOOL get_RadarRegion_passed(RadarRegion *obj) { return obj.passed; }
RADAR_API_SURFACE BOOL get_RadarRegion_inExclusionZone(RadarRegion *obj) { return obj.inExclusionZone; }
RADAR_API_SURFACE BOOL get_RadarRegion_inBufferZone(RadarRegion *obj) { return obj.inBufferZone; }
RADAR_API_SURFACE double get_RadarRegion_distanceToBorder(RadarRegion *obj) { return obj.distanceToBorder; }
RADAR_API_SURFACE BOOL get_RadarRegion_expected(RadarRegion *obj) { return obj.expected; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarRegion_dictionaryValue(RadarRegion *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarRevealRiskIpGeometry

RADAR_API_SURFACE Class class_RadarRevealRiskIpGeometry(void) { return [RadarRevealRiskIpGeometry class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRevealRiskIpGeometry_type(RadarRevealRiskIpGeometry *obj) { return obj.type; }
RADAR_API_SURFACE NSArray<NSNumber *> *_Nonnull get_RadarRevealRiskIpGeometry_coordinates(RadarRevealRiskIpGeometry *obj) { return obj.coordinates; }

#pragma mark - RadarRevealRiskToken

RADAR_API_SURFACE Class class_RadarRevealRiskToken(void) { return [RadarRevealRiskToken class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRevealRiskToken__id(RadarRevealRiskToken *obj) { return obj._id; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskToken_token(RadarRevealRiskToken *obj) { return obj.token; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarRevealRiskToken_expiresAt(RadarRevealRiskToken *obj) { return obj.expiresAt; }
RADAR_API_SURFACE NSNumber *_Nullable get_RadarRevealRiskToken_expiresIn(RadarRevealRiskToken *obj) { return obj.expiresIn; }
RADAR_API_SURFACE RadarRevealRiskTokenRisk *_Nonnull get_RadarRevealRiskToken_risk(RadarRevealRiskToken *obj) { return obj.risk; }
RADAR_API_SURFACE RadarRevealRiskTokenNetwork *_Nonnull get_RadarRevealRiskToken_network(RadarRevealRiskToken *obj) { return obj.network; }
RADAR_API_SURFACE RadarRevealRiskTokenDevice *_Nonnull get_RadarRevealRiskToken_device(RadarRevealRiskToken *obj) { return obj.device; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarRevealRiskToken_dictionaryValue(RadarRevealRiskToken *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarRevealRiskTokenDevice

RADAR_API_SURFACE Class class_RadarRevealRiskTokenDevice(void) { return [RadarRevealRiskTokenDevice class]; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_deviceId(RadarRevealRiskTokenDevice *obj) { return obj.deviceId; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_deviceType(RadarRevealRiskTokenDevice *obj) { return obj.deviceType; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_deviceMake(RadarRevealRiskTokenDevice *obj) { return obj.deviceMake; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_deviceModel(RadarRevealRiskTokenDevice *obj) { return obj.deviceModel; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_deviceOSName(RadarRevealRiskTokenDevice *obj) { return obj.deviceOSName; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_deviceOSVersion(RadarRevealRiskTokenDevice *obj) { return obj.deviceOSVersion; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_sdkVersion(RadarRevealRiskTokenDevice *obj) { return obj.sdkVersion; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_xPlatformType(RadarRevealRiskTokenDevice *obj) { return obj.xPlatformType; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_installId(RadarRevealRiskTokenDevice *obj) { return obj.installId; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_appId(RadarRevealRiskTokenDevice *obj) { return obj.appId; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_appName(RadarRevealRiskTokenDevice *obj) { return obj.appName; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_appVersion(RadarRevealRiskTokenDevice *obj) { return obj.appVersion; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenDevice_appBuild(RadarRevealRiskTokenDevice *obj) { return obj.appBuild; }

#pragma mark - RadarRevealRiskTokenNetwork

RADAR_API_SURFACE Class class_RadarRevealRiskTokenNetwork(void) { return [RadarRevealRiskTokenNetwork class]; }
RADAR_API_SURFACE RadarRevealRiskTokenNetworkIpAddress *_Nullable get_RadarRevealRiskTokenNetwork_ipAddress(RadarRevealRiskTokenNetwork *obj) { return obj.ipAddress; }
RADAR_API_SURFACE RadarRevealRiskTokenNetworkPrivacy *_Nullable get_RadarRevealRiskTokenNetwork_privacy(RadarRevealRiskTokenNetwork *obj) { return obj.privacy; }
RADAR_API_SURFACE RadarRevealRiskTokenNetworkAsn *_Nullable get_RadarRevealRiskTokenNetwork_asn(RadarRevealRiskTokenNetwork *obj) { return obj.asn; }

#pragma mark - RadarRevealRiskTokenNetworkAsn

RADAR_API_SURFACE Class class_RadarRevealRiskTokenNetworkAsn(void) { return [RadarRevealRiskTokenNetworkAsn class]; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkAsn_asn(RadarRevealRiskTokenNetworkAsn *obj) { return obj.asn; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkAsn_country(RadarRevealRiskTokenNetworkAsn *obj) { return obj.country; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkAsn_domain(RadarRevealRiskTokenNetworkAsn *obj) { return obj.domain; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkAsn_name(RadarRevealRiskTokenNetworkAsn *obj) { return obj.name; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkAsn_network(RadarRevealRiskTokenNetworkAsn *obj) { return obj.network; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkAsn_type(RadarRevealRiskTokenNetworkAsn *obj) { return obj.type; }

#pragma mark - RadarRevealRiskTokenNetworkIpAddress

RADAR_API_SURFACE Class class_RadarRevealRiskTokenNetworkIpAddress(void) { return [RadarRevealRiskTokenNetworkIpAddress class]; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_countryCode(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.countryCode; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_country(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.country; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_countryFlag(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.countryFlag; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_state(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.state; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_city(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.city; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_postalCode(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.postalCode; }
RADAR_API_SURFACE NSNumber *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_latitude(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.latitude; }
RADAR_API_SURFACE NSNumber *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_longitude(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.longitude; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_connectionType(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.connectionType; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_stateCode(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.stateCode; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_stateConfidence(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.stateConfidence; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_countryConfidence(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.countryConfidence; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_dma(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.dma; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_dmaCode(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.dmaCode; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkIpAddress_stateAllowed(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.stateAllowed; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkIpAddress_countryAllowed(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.countryAllowed; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_layer(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.layer; }
RADAR_API_SURFACE RadarRevealRiskIpGeometry *_Nullable get_RadarRevealRiskTokenNetworkIpAddress_geometry(RadarRevealRiskTokenNetworkIpAddress *obj) { return obj.geometry; }

#pragma mark - RadarRevealRiskTokenNetworkPrivacy

RADAR_API_SURFACE Class class_RadarRevealRiskTokenNetworkPrivacy(void) { return [RadarRevealRiskTokenNetworkPrivacy class]; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkPrivacy_hosting(RadarRevealRiskTokenNetworkPrivacy *obj) { return obj.hosting; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkPrivacy_proxy(RadarRevealRiskTokenNetworkPrivacy *obj) { return obj.proxy; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkPrivacy_relay(RadarRevealRiskTokenNetworkPrivacy *obj) { return obj.relay; }
RADAR_API_SURFACE NSString *_Nullable get_RadarRevealRiskTokenNetworkPrivacy_service(RadarRevealRiskTokenNetworkPrivacy *obj) { return obj.service; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkPrivacy_tor(RadarRevealRiskTokenNetworkPrivacy *obj) { return obj.tor; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkPrivacy_vpn(RadarRevealRiskTokenNetworkPrivacy *obj) { return obj.vpn; }
RADAR_API_SURFACE BOOL get_RadarRevealRiskTokenNetworkPrivacy_residentialProxy(RadarRevealRiskTokenNetworkPrivacy *obj) { return obj.residentialProxy; }

#pragma mark - RadarRevealRiskTokenRisk

RADAR_API_SURFACE Class class_RadarRevealRiskTokenRisk(void) { return [RadarRevealRiskTokenRisk class]; }
RADAR_API_SURFACE enum RadarRevealRiskLevel get_RadarRevealRiskTokenRisk_level(RadarRevealRiskTokenRisk *obj) { return obj.level; }
RADAR_API_SURFACE NSArray<NSString *> *_Nonnull get_RadarRevealRiskTokenRisk_reasons(RadarRevealRiskTokenRisk *obj) { return obj.reasons; }

#pragma mark - RadarRoute

RADAR_API_SURFACE Class class_RadarRoute(void) { return [RadarRoute class]; }
RADAR_API_SURFACE RadarRouteDistance *_Nonnull get_RadarRoute_distance(RadarRoute *obj) { return obj.distance; }
RADAR_API_SURFACE RadarRouteDuration *_Nonnull get_RadarRoute_duration(RadarRoute *obj) { return obj.duration; }
RADAR_API_SURFACE RadarRouteGeometry *_Nonnull get_RadarRoute_geometry(RadarRoute *obj) { return obj.geometry; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarRoute_dictionaryValue(RadarRoute *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarRouteDistance

RADAR_API_SURFACE Class class_RadarRouteDistance(void) { return [RadarRouteDistance class]; }
RADAR_API_SURFACE double get_RadarRouteDistance_value(RadarRouteDistance *obj) { return obj.value; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRouteDistance_text(RadarRouteDistance *obj) { return obj.text; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarRouteDistance_dictionaryValue(RadarRouteDistance *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarRouteDuration

RADAR_API_SURFACE Class class_RadarRouteDuration(void) { return [RadarRouteDuration class]; }
RADAR_API_SURFACE double get_RadarRouteDuration_value(RadarRouteDuration *obj) { return obj.value; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarRouteDuration_text(RadarRouteDuration *obj) { return obj.text; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarRouteDuration_dictionaryValue(RadarRouteDuration *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarRouteGeometry

RADAR_API_SURFACE Class class_RadarRouteGeometry(void) { return [RadarRouteGeometry class]; }
RADAR_API_SURFACE NSArray<RadarCoordinate *> *_Nullable get_RadarRouteGeometry_coordinates(RadarRouteGeometry *obj) { return obj.coordinates; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarRouteGeometry_dictionaryValue(RadarRouteGeometry *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarRouteMatrix

RADAR_API_SURFACE Class class_RadarRouteMatrix(void) { return [RadarRouteMatrix class]; }
RADAR_API_SURFACE RadarRoute *_Nullable call_RadarRouteMatrix_routeBetweenOriginIndex_destinationIndex(RadarRouteMatrix *obj, NSInteger a0, NSInteger a1) {
    return [obj routeBetweenOriginIndex:a0 destinationIndex:a1];
}
RADAR_API_SURFACE NSArray<NSArray<NSDictionary *> *> *_Nonnull call_RadarRouteMatrix_arrayValue(RadarRouteMatrix *obj) { return [obj arrayValue]; }

#pragma mark - RadarRoutes

RADAR_API_SURFACE Class class_RadarRoutes(void) { return [RadarRoutes class]; }
RADAR_API_SURFACE RadarRouteDistance *_Nullable get_RadarRoutes_geodesic(RadarRoutes *obj) { return obj.geodesic; }
RADAR_API_SURFACE RadarRoute *_Nullable get_RadarRoutes_foot(RadarRoutes *obj) { return obj.foot; }
RADAR_API_SURFACE RadarRoute *_Nullable get_RadarRoutes_bike(RadarRoutes *obj) { return obj.bike; }
RADAR_API_SURFACE RadarRoute *_Nullable get_RadarRoutes_car(RadarRoutes *obj) { return obj.car; }
RADAR_API_SURFACE RadarRoute *_Nullable get_RadarRoutes_truck(RadarRoutes *obj) { return obj.truck; }
RADAR_API_SURFACE RadarRoute *_Nullable get_RadarRoutes_motorbike(RadarRoutes *obj) { return obj.motorbike; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarRoutes_dictionaryValue(RadarRoutes *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarTimeZone

RADAR_API_SURFACE Class class_RadarTimeZone(void) { return [RadarTimeZone class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarTimeZone__id(RadarTimeZone *obj) { return obj._id; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarTimeZone_name(RadarTimeZone *obj) { return obj.name; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarTimeZone_code(RadarTimeZone *obj) { return obj.code; }
RADAR_API_SURFACE NSDate *_Nonnull get_RadarTimeZone_currentTime(RadarTimeZone *obj) { return obj.currentTime; }
RADAR_API_SURFACE int32_t get_RadarTimeZone_utcOffset(RadarTimeZone *obj) { return obj.utcOffset; }
RADAR_API_SURFACE int32_t get_RadarTimeZone_dstOffset(RadarTimeZone *obj) { return obj.dstOffset; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarTimeZone_dictionaryValue(RadarTimeZone *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarTrackingOptions

RADAR_API_SURFACE Class class_RadarTrackingOptions(void) { return [RadarTrackingOptions class]; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_desiredStoppedUpdateInterval(RadarTrackingOptions *obj) { return obj.desiredStoppedUpdateInterval; }
RADAR_API_SURFACE void set_RadarTrackingOptions_desiredStoppedUpdateInterval(RadarTrackingOptions *obj, int32_t value) { obj.desiredStoppedUpdateInterval = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_desiredMovingUpdateInterval(RadarTrackingOptions *obj) { return obj.desiredMovingUpdateInterval; }
RADAR_API_SURFACE void set_RadarTrackingOptions_desiredMovingUpdateInterval(RadarTrackingOptions *obj, int32_t value) { obj.desiredMovingUpdateInterval = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_desiredSyncInterval(RadarTrackingOptions *obj) { return obj.desiredSyncInterval; }
RADAR_API_SURFACE void set_RadarTrackingOptions_desiredSyncInterval(RadarTrackingOptions *obj, int32_t value) { obj.desiredSyncInterval = value; }
RADAR_API_SURFACE RadarTrackingOptionsDesiredAccuracy get_RadarTrackingOptions_desiredAccuracy(RadarTrackingOptions *obj) { return obj.desiredAccuracy; }
RADAR_API_SURFACE void set_RadarTrackingOptions_desiredAccuracy(RadarTrackingOptions *obj, RadarTrackingOptionsDesiredAccuracy value) { obj.desiredAccuracy = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_stopDuration(RadarTrackingOptions *obj) { return obj.stopDuration; }
RADAR_API_SURFACE void set_RadarTrackingOptions_stopDuration(RadarTrackingOptions *obj, int32_t value) { obj.stopDuration = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_stopDistance(RadarTrackingOptions *obj) { return obj.stopDistance; }
RADAR_API_SURFACE void set_RadarTrackingOptions_stopDistance(RadarTrackingOptions *obj, int32_t value) { obj.stopDistance = value; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarTrackingOptions_startTrackingAfter(RadarTrackingOptions *obj) { return obj.startTrackingAfter; }
RADAR_API_SURFACE void set_RadarTrackingOptions_startTrackingAfter(RadarTrackingOptions *obj, NSDate *_Nullable value) { obj.startTrackingAfter = value; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarTrackingOptions_stopTrackingAfter(RadarTrackingOptions *obj) { return obj.stopTrackingAfter; }
RADAR_API_SURFACE void set_RadarTrackingOptions_stopTrackingAfter(RadarTrackingOptions *obj, NSDate *_Nullable value) { obj.stopTrackingAfter = value; }
RADAR_API_SURFACE RadarTrackingOptionsReplay get_RadarTrackingOptions_replay(RadarTrackingOptions *obj) { return obj.replay; }
RADAR_API_SURFACE void set_RadarTrackingOptions_replay(RadarTrackingOptions *obj, RadarTrackingOptionsReplay value) { obj.replay = value; }
RADAR_API_SURFACE RadarTrackingOptionsSyncLocations get_RadarTrackingOptions_syncLocations(RadarTrackingOptions *obj) { return obj.syncLocations; }
RADAR_API_SURFACE void set_RadarTrackingOptions_syncLocations(RadarTrackingOptions *obj, RadarTrackingOptionsSyncLocations value) { obj.syncLocations = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_showBlueBar(RadarTrackingOptions *obj) { return obj.showBlueBar; }
RADAR_API_SURFACE void set_RadarTrackingOptions_showBlueBar(RadarTrackingOptions *obj, BOOL value) { obj.showBlueBar = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_useStoppedGeofence(RadarTrackingOptions *obj) { return obj.useStoppedGeofence; }
RADAR_API_SURFACE void set_RadarTrackingOptions_useStoppedGeofence(RadarTrackingOptions *obj, BOOL value) { obj.useStoppedGeofence = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_stoppedGeofenceRadius(RadarTrackingOptions *obj) { return obj.stoppedGeofenceRadius; }
RADAR_API_SURFACE void set_RadarTrackingOptions_stoppedGeofenceRadius(RadarTrackingOptions *obj, int32_t value) { obj.stoppedGeofenceRadius = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_useMovingGeofence(RadarTrackingOptions *obj) { return obj.useMovingGeofence; }
RADAR_API_SURFACE void set_RadarTrackingOptions_useMovingGeofence(RadarTrackingOptions *obj, BOOL value) { obj.useMovingGeofence = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_movingGeofenceRadius(RadarTrackingOptions *obj) { return obj.movingGeofenceRadius; }
RADAR_API_SURFACE void set_RadarTrackingOptions_movingGeofenceRadius(RadarTrackingOptions *obj, int32_t value) { obj.movingGeofenceRadius = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_syncGeofences(RadarTrackingOptions *obj) { return obj.syncGeofences; }
RADAR_API_SURFACE void set_RadarTrackingOptions_syncGeofences(RadarTrackingOptions *obj, BOOL value) { obj.syncGeofences = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_useVisits(RadarTrackingOptions *obj) { return obj.useVisits; }
RADAR_API_SURFACE void set_RadarTrackingOptions_useVisits(RadarTrackingOptions *obj, BOOL value) { obj.useVisits = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_useSignificantLocationChanges(RadarTrackingOptions *obj) { return obj.useSignificantLocationChanges; }
RADAR_API_SURFACE void set_RadarTrackingOptions_useSignificantLocationChanges(RadarTrackingOptions *obj, BOOL value) { obj.useSignificantLocationChanges = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_beacons(RadarTrackingOptions *obj) { return obj.beacons; }
RADAR_API_SURFACE void set_RadarTrackingOptions_beacons(RadarTrackingOptions *obj, BOOL value) { obj.beacons = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_useIndoorScan(RadarTrackingOptions *obj) { return obj.useIndoorScan; }
RADAR_API_SURFACE void set_RadarTrackingOptions_useIndoorScan(RadarTrackingOptions *obj, BOOL value) { obj.useIndoorScan = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_useMotion(RadarTrackingOptions *obj) { return obj.useMotion; }
RADAR_API_SURFACE void set_RadarTrackingOptions_useMotion(RadarTrackingOptions *obj, BOOL value) { obj.useMotion = value; }
RADAR_API_SURFACE BOOL get_RadarTrackingOptions_usePressure(RadarTrackingOptions *obj) { return obj.usePressure; }
RADAR_API_SURFACE void set_RadarTrackingOptions_usePressure(RadarTrackingOptions *obj, BOOL value) { obj.usePressure = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_batchInterval(RadarTrackingOptions *obj) { return obj.batchInterval; }
RADAR_API_SURFACE void set_RadarTrackingOptions_batchInterval(RadarTrackingOptions *obj, int32_t value) { obj.batchInterval = value; }
RADAR_API_SURFACE int32_t get_RadarTrackingOptions_batchSize(RadarTrackingOptions *obj) { return obj.batchSize; }
RADAR_API_SURFACE void set_RadarTrackingOptions_batchSize(RadarTrackingOptions *obj, int32_t value) { obj.batchSize = value; }
RADAR_API_SURFACE RadarTrackingOptionsType get_RadarTrackingOptions_type(RadarTrackingOptions *obj) { return obj.type; }
RADAR_API_SURFACE void set_RadarTrackingOptions_type(RadarTrackingOptions *obj, RadarTrackingOptionsType value) { obj.type = value; }
RADAR_API_SURFACE RadarTrackingOptions *_Nonnull get_RadarTrackingOptions_class_presetContinuous(void) { return RadarTrackingOptions.presetContinuous; }
RADAR_API_SURFACE RadarTrackingOptions *_Nonnull get_RadarTrackingOptions_class_presetResponsive(void) { return RadarTrackingOptions.presetResponsive; }
RADAR_API_SURFACE RadarTrackingOptions *_Nonnull get_RadarTrackingOptions_class_presetEfficient(void) { return RadarTrackingOptions.presetEfficient; }
RADAR_API_SURFACE NSString *_Nonnull call_RadarTrackingOptions_class_stringForDesiredAccuracy(RadarTrackingOptionsDesiredAccuracy a0) {
    return [RadarTrackingOptions stringForDesiredAccuracy:a0];
}
RADAR_API_SURFACE RadarTrackingOptionsDesiredAccuracy call_RadarTrackingOptions_class_desiredAccuracyForString(NSString *_Nonnull a0) {
    return [RadarTrackingOptions desiredAccuracyForString:a0];
}
RADAR_API_SURFACE NSString *_Nonnull call_RadarTrackingOptions_class_stringForReplay(RadarTrackingOptionsReplay a0) { return [RadarTrackingOptions stringForReplay:a0]; }
RADAR_API_SURFACE RadarTrackingOptionsReplay call_RadarTrackingOptions_class_replayForString(NSString *_Nonnull a0) { return [RadarTrackingOptions replayForString:a0]; }
RADAR_API_SURFACE NSString *_Nonnull call_RadarTrackingOptions_class_stringForSyncLocations(RadarTrackingOptionsSyncLocations a0) {
    return [RadarTrackingOptions stringForSyncLocations:a0];
}
RADAR_API_SURFACE RadarTrackingOptionsSyncLocations call_RadarTrackingOptions_class_syncLocationsForString(NSString *_Nonnull a0) {
    return [RadarTrackingOptions syncLocationsForString:a0];
}
RADAR_API_SURFACE NSString *_Nonnull call_RadarTrackingOptions_class_stringForType(RadarTrackingOptionsType a0) { return [RadarTrackingOptions stringForType:a0]; }
RADAR_API_SURFACE RadarTrackingOptionsType call_RadarTrackingOptions_class_typeForString(NSString *_Nonnull a0) { return [RadarTrackingOptions typeForString:a0]; }
RADAR_API_SURFACE RadarTrackingOptions *_Nullable call_RadarTrackingOptions_class_trackingOptionsFromDictionary(NSDictionary *_Nonnull a0) {
    return [RadarTrackingOptions trackingOptionsFromDictionary:a0];
}
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarTrackingOptions_dictionaryValue(RadarTrackingOptions *obj) { return [obj dictionaryValue]; }
RADAR_API_SURFACE BOOL call_RadarTrackingOptions_isEqual(RadarTrackingOptions *obj, id _Nullable a0) { return [obj isEqual:a0]; }
RADAR_API_SURFACE RadarTrackingOptions *_Nonnull call_RadarTrackingOptions_init(void) { return [[RadarTrackingOptions alloc] init]; }

#pragma mark - RadarTrip

RADAR_API_SURFACE Class class_RadarTrip(void) { return [RadarTrip class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarTrip__id(RadarTrip *obj) { return obj._id; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTrip_externalId(RadarTrip *obj) { return obj.externalId; }
RADAR_API_SURFACE NSDictionary *_Nullable get_RadarTrip_metadata(RadarTrip *obj) { return obj.metadata; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTrip_destinationGeofenceTag(RadarTrip *obj) { return obj.destinationGeofenceTag; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTrip_destinationGeofenceExternalId(RadarTrip *obj) { return obj.destinationGeofenceExternalId; }
RADAR_API_SURFACE RadarCoordinate *_Nullable get_RadarTrip_destinationLocation(RadarTrip *obj) { return obj.destinationLocation; }
RADAR_API_SURFACE RadarRouteMode get_RadarTrip_mode(RadarTrip *obj) { return obj.mode; }
RADAR_API_SURFACE float get_RadarTrip_etaDistance(RadarTrip *obj) { return obj.etaDistance; }
RADAR_API_SURFACE float get_RadarTrip_etaDuration(RadarTrip *obj) { return obj.etaDuration; }
RADAR_API_SURFACE RadarTripStatus get_RadarTrip_status(RadarTrip *obj) { return obj.status; }
RADAR_API_SURFACE NSArray<RadarTripOrder *> *_Nullable get_RadarTrip_orders(RadarTrip *obj) { return obj.orders; }
RADAR_API_SURFACE NSArray<RadarTripLeg *> *_Nullable get_RadarTrip_legs(RadarTrip *obj) { return obj.legs; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTrip_currentLegId(RadarTrip *obj) { return obj.currentLegId; }
RADAR_API_SURFACE RadarTrip *_Nullable call_RadarTrip_initWithObject(id _Nonnull a0) { return [[RadarTrip alloc] initWithObject:a0]; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarTrip_dictionaryValue(RadarTrip *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarTripLeg

RADAR_API_SURFACE Class class_RadarTripLeg(void) { return [RadarTripLeg class]; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripLeg__id(RadarTripLeg *obj) { return obj._id; }
RADAR_API_SURFACE RadarTripLegStatus get_RadarTripLeg_status(RadarTripLeg *obj) { return obj.status; }
RADAR_API_SURFACE RadarTripLegDestinationType get_RadarTripLeg_destinationType(RadarTripLeg *obj) { return obj.destinationType; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarTripLeg_createdAt(RadarTripLeg *obj) { return obj.createdAt; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarTripLeg_updatedAt(RadarTripLeg *obj) { return obj.updatedAt; }
RADAR_API_SURFACE float get_RadarTripLeg_etaDuration(RadarTripLeg *obj) { return obj.etaDuration; }
RADAR_API_SURFACE float get_RadarTripLeg_etaDistance(RadarTripLeg *obj) { return obj.etaDistance; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripLeg_destinationGeofenceTag(RadarTripLeg *obj) { return obj.destinationGeofenceTag; }
RADAR_API_SURFACE void set_RadarTripLeg_destinationGeofenceTag(RadarTripLeg *obj, NSString *_Nullable value) { obj.destinationGeofenceTag = value; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripLeg_destinationGeofenceExternalId(RadarTripLeg *obj) { return obj.destinationGeofenceExternalId; }
RADAR_API_SURFACE void set_RadarTripLeg_destinationGeofenceExternalId(RadarTripLeg *obj, NSString *_Nullable value) { obj.destinationGeofenceExternalId = value; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripLeg_destinationGeofenceId(RadarTripLeg *obj) { return obj.destinationGeofenceId; }
RADAR_API_SURFACE void set_RadarTripLeg_destinationGeofenceId(RadarTripLeg *obj, NSString *_Nullable value) { obj.destinationGeofenceId = value; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripLeg_address(RadarTripLeg *obj) { return obj.address; }
RADAR_API_SURFACE void set_RadarTripLeg_address(RadarTripLeg *obj, NSString *_Nullable value) { obj.address = value; }
RADAR_API_SURFACE CLLocationCoordinate2D get_RadarTripLeg_coordinates(RadarTripLeg *obj) { return obj.coordinates; }
RADAR_API_SURFACE void set_RadarTripLeg_coordinates(RadarTripLeg *obj, CLLocationCoordinate2D value) { obj.coordinates = value; }
RADAR_API_SURFACE BOOL get_RadarTripLeg_hasCoordinates(RadarTripLeg *obj) { return obj.hasCoordinates; }
RADAR_API_SURFACE NSInteger get_RadarTripLeg_arrivalRadius(RadarTripLeg *obj) { return obj.arrivalRadius; }
RADAR_API_SURFACE void set_RadarTripLeg_arrivalRadius(RadarTripLeg *obj, NSInteger value) { obj.arrivalRadius = value; }
RADAR_API_SURFACE NSInteger get_RadarTripLeg_stopDuration(RadarTripLeg *obj) { return obj.stopDuration; }
RADAR_API_SURFACE void set_RadarTripLeg_stopDuration(RadarTripLeg *obj, NSInteger value) { obj.stopDuration = value; }
RADAR_API_SURFACE NSDictionary *_Nullable get_RadarTripLeg_metadata(RadarTripLeg *obj) { return obj.metadata; }
RADAR_API_SURFACE void set_RadarTripLeg_metadata(RadarTripLeg *obj, NSDictionary *_Nullable value) { obj.metadata = value; }
RADAR_API_SURFACE RadarTripLeg *_Nonnull call_RadarTripLeg_init(void) { return [[RadarTripLeg alloc] init]; }
RADAR_API_SURFACE RadarTripLeg *_Nonnull call_RadarTripLeg_initWithDestinationGeofenceTag_destinationGeofenceExternalId(NSString *_Nullable a0, NSString *_Nullable a1) {
    return [[RadarTripLeg alloc] initWithDestinationGeofenceTag:a0 destinationGeofenceExternalId:a1];
}
RADAR_API_SURFACE RadarTripLeg *_Nonnull call_RadarTripLeg_initWithDestinationGeofenceId(NSString *_Nonnull a0) { return [[RadarTripLeg alloc] initWithDestinationGeofenceId:a0]; }
RADAR_API_SURFACE RadarTripLeg *_Nonnull call_RadarTripLeg_initWithAddress(NSString *_Nonnull a0) { return [[RadarTripLeg alloc] initWithAddress:a0]; }
RADAR_API_SURFACE RadarTripLeg *_Nonnull call_RadarTripLeg_initWithCoordinates(CLLocationCoordinate2D a0) { return [[RadarTripLeg alloc] initWithCoordinates:a0]; }
RADAR_API_SURFACE NSString *_Nonnull call_RadarTripLeg_class_stringForStatus(RadarTripLegStatus a0) { return [RadarTripLeg stringForStatus:a0]; }
RADAR_API_SURFACE RadarTripLegStatus call_RadarTripLeg_class_statusForString(NSString *_Nonnull a0) { return [RadarTripLeg statusForString:a0]; }
RADAR_API_SURFACE NSString *_Nonnull call_RadarTripLeg_class_stringForDestinationType(RadarTripLegDestinationType a0) { return [RadarTripLeg stringForDestinationType:a0]; }
RADAR_API_SURFACE RadarTripLegDestinationType call_RadarTripLeg_class_destinationTypeForString(NSString *_Nonnull a0) { return [RadarTripLeg destinationTypeForString:a0]; }
RADAR_API_SURFACE RadarTripLeg *_Nullable call_RadarTripLeg_class_legFromDictionary(id _Nullable a0) { return [RadarTripLeg legFromDictionary:a0]; }
RADAR_API_SURFACE NSArray<RadarTripLeg *> *_Nullable call_RadarTripLeg_class_legsFromArray(NSArray *_Nullable a0) { return [RadarTripLeg legsFromArray:a0]; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarTripLeg_dictionaryValue(RadarTripLeg *obj) { return [obj dictionaryValue]; }
RADAR_API_SURFACE NSArray<NSDictionary *> *_Nullable call_RadarTripLeg_class_arrayForLegs(NSArray<RadarTripLeg *> *_Nullable a0) { return [RadarTripLeg arrayForLegs:a0]; }
RADAR_API_SURFACE BOOL call_RadarTripLeg_isEqual(RadarTripLeg *obj, id _Nullable a0) { return [obj isEqual:a0]; }

#pragma mark - RadarTripOptions

RADAR_API_SURFACE Class class_RadarTripOptions(void) { return [RadarTripOptions class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarTripOptions_externalId(RadarTripOptions *obj) { return obj.externalId; }
RADAR_API_SURFACE void set_RadarTripOptions_externalId(RadarTripOptions *obj, NSString *_Nonnull value) { obj.externalId = value; }
RADAR_API_SURFACE NSDictionary *_Nullable get_RadarTripOptions_metadata(RadarTripOptions *obj) { return obj.metadata; }
RADAR_API_SURFACE void set_RadarTripOptions_metadata(RadarTripOptions *obj, NSDictionary *_Nullable value) { obj.metadata = value; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripOptions_destinationGeofenceTag(RadarTripOptions *obj) { return obj.destinationGeofenceTag; }
RADAR_API_SURFACE void set_RadarTripOptions_destinationGeofenceTag(RadarTripOptions *obj, NSString *_Nullable value) { obj.destinationGeofenceTag = value; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripOptions_destinationGeofenceExternalId(RadarTripOptions *obj) { return obj.destinationGeofenceExternalId; }
RADAR_API_SURFACE void set_RadarTripOptions_destinationGeofenceExternalId(RadarTripOptions *obj, NSString *_Nullable value) { obj.destinationGeofenceExternalId = value; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarTripOptions_scheduledArrivalAt(RadarTripOptions *obj) { return obj.scheduledArrivalAt; }
RADAR_API_SURFACE void set_RadarTripOptions_scheduledArrivalAt(RadarTripOptions *obj, NSDate *_Nullable value) { obj.scheduledArrivalAt = value; }
RADAR_API_SURFACE RadarRouteMode get_RadarTripOptions_mode(RadarTripOptions *obj) { return obj.mode; }
RADAR_API_SURFACE void set_RadarTripOptions_mode(RadarTripOptions *obj, RadarRouteMode value) { obj.mode = value; }
RADAR_API_SURFACE uint16_t get_RadarTripOptions_approachingThreshold(RadarTripOptions *obj) { return obj.approachingThreshold; }
RADAR_API_SURFACE void set_RadarTripOptions_approachingThreshold(RadarTripOptions *obj, uint16_t value) { obj.approachingThreshold = value; }
RADAR_API_SURFACE BOOL get_RadarTripOptions_startTracking(RadarTripOptions *obj) { return obj.startTracking; }
RADAR_API_SURFACE void set_RadarTripOptions_startTracking(RadarTripOptions *obj, BOOL value) { obj.startTracking = value; }
RADAR_API_SURFACE NSArray<RadarTripLeg *> *_Nullable get_RadarTripOptions_legs(RadarTripOptions *obj) { return obj.legs; }
RADAR_API_SURFACE void set_RadarTripOptions_legs(RadarTripOptions *obj, NSArray<RadarTripLeg *> *_Nullable value) { obj.legs = value; }
RADAR_API_SURFACE RadarTripOptions *_Nonnull call_RadarTripOptions_init(void) { return [[RadarTripOptions alloc] init]; }
RADAR_API_SURFACE RadarTripOptions *_Nonnull call_RadarTripOptions_initWithExternalId_destinationGeofenceTag_destinationGeofenceExternalId(NSString *_Nonnull a0,
                                                                                                                                           NSString *_Nullable a1,
                                                                                                                                           NSString *_Nullable a2) {
    return [[RadarTripOptions alloc] initWithExternalId:a0 destinationGeofenceTag:a1 destinationGeofenceExternalId:a2];
}
RADAR_API_SURFACE RadarTripOptions *_Nonnull call_RadarTripOptions_initWithExternalId_destinationGeofenceTag_destinationGeofenceExternalId_scheduledArrivalAt(
    NSString *_Nonnull a0, NSString *_Nullable a1, NSString *_Nullable a2, NSDate *_Nullable a3) {
    return [[RadarTripOptions alloc] initWithExternalId:a0 destinationGeofenceTag:a1 destinationGeofenceExternalId:a2 scheduledArrivalAt:a3];
}
RADAR_API_SURFACE RadarTripOptions *_Nonnull call_RadarTripOptions_initWithExternalId_destinationGeofenceTag_destinationGeofenceExternalId_scheduledArrivalAt_startTracking(
    NSString *_Nonnull a0, NSString *_Nullable a1, NSString *_Nullable a2, NSDate *_Nullable a3, BOOL a4) {
    return [[RadarTripOptions alloc] initWithExternalId:a0 destinationGeofenceTag:a1 destinationGeofenceExternalId:a2 scheduledArrivalAt:a3 startTracking:a4];
}
RADAR_API_SURFACE RadarTripOptions *_Nullable call_RadarTripOptions_class_tripOptionsFromDictionary(NSDictionary *_Nullable a0) {
    return [RadarTripOptions tripOptionsFromDictionary:a0];
}
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarTripOptions_dictionaryValue(RadarTripOptions *obj) { return [obj dictionaryValue]; }
RADAR_API_SURFACE BOOL call_RadarTripOptions_isEqual(RadarTripOptions *obj, id _Nullable a0) { return [obj isEqual:a0]; }

#pragma mark - RadarTripOrder

RADAR_API_SURFACE Class class_RadarTripOrder(void) { return [RadarTripOrder class]; }
RADAR_API_SURFACE NSString *_Nonnull get_RadarTripOrder__id(RadarTripOrder *obj) { return obj._id; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripOrder_guid(RadarTripOrder *obj) { return obj.guid; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripOrder_handoffMode(RadarTripOrder *obj) { return obj.handoffMode; }
RADAR_API_SURFACE RadarTripOrderStatus get_RadarTripOrder_status(RadarTripOrder *obj) { return obj.status; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarTripOrder_firedAt(RadarTripOrder *obj) { return obj.firedAt; }
RADAR_API_SURFACE NSNumber *_Nullable get_RadarTripOrder_firedAttempts(RadarTripOrder *obj) { return obj.firedAttempts; }
RADAR_API_SURFACE NSString *_Nullable get_RadarTripOrder_firedReason(RadarTripOrder *obj) { return obj.firedReason; }
RADAR_API_SURFACE NSDate *_Nonnull get_RadarTripOrder_updatedAt(RadarTripOrder *obj) { return obj.updatedAt; }
RADAR_API_SURFACE RadarTripOrder *_Nullable call_RadarTripOrder_initWithId_guid_handoffMode_status_firedAt_firedAttempts_firedReason_updatedAt(NSString *_Nonnull a0,
                                                                                                                                               NSString *_Nullable a1,
                                                                                                                                               NSString *_Nullable a2,
                                                                                                                                               RadarTripOrderStatus a3,
                                                                                                                                               NSDate *_Nullable a4,
                                                                                                                                               NSNumber *_Nullable a5,
                                                                                                                                               NSString *_Nullable a6,
                                                                                                                                               NSDate *_Nonnull a7) {
    return [[RadarTripOrder alloc] initWithId:a0 guid:a1 handoffMode:a2 status:a3 firedAt:a4 firedAttempts:a5 firedReason:a6 updatedAt:a7];
}
RADAR_API_SURFACE RadarTripOrder *_Nullable call_RadarTripOrder_initWithObject(id _Nonnull a0) { return [[RadarTripOrder alloc] initWithObject:a0]; }
RADAR_API_SURFACE NSArray<RadarTripOrder *> *_Nullable call_RadarTripOrder_class_ordersFromObject(id _Nonnull a0) { return [RadarTripOrder ordersFromObject:a0]; }
RADAR_API_SURFACE NSArray<NSDictionary *> *_Nullable call_RadarTripOrder_class_arrayForOrders(NSArray<RadarTripOrder *> *_Nullable a0) {
    return [RadarTripOrder arrayForOrders:a0];
}
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarTripOrder_dictionaryValue(RadarTripOrder *obj) { return [obj dictionaryValue]; }

#pragma mark - RadarVerifiedLocationToken

RADAR_API_SURFACE Class class_RadarVerifiedLocationToken(void) { return [RadarVerifiedLocationToken class]; }
RADAR_API_SURFACE RadarUser *_Nullable get_RadarVerifiedLocationToken_user(RadarVerifiedLocationToken *obj) { return obj.user; }
RADAR_API_SURFACE NSArray<RadarEvent *> *_Nullable get_RadarVerifiedLocationToken_events(RadarVerifiedLocationToken *obj) { return obj.events; }
RADAR_API_SURFACE NSString *_Nullable get_RadarVerifiedLocationToken_token(RadarVerifiedLocationToken *obj) { return obj.token; }
RADAR_API_SURFACE NSDate *_Nullable get_RadarVerifiedLocationToken_expiresAt(RadarVerifiedLocationToken *obj) { return obj.expiresAt; }
RADAR_API_SURFACE NSTimeInterval get_RadarVerifiedLocationToken_expiresIn(RadarVerifiedLocationToken *obj) { return obj.expiresIn; }
RADAR_API_SURFACE BOOL get_RadarVerifiedLocationToken_passed(RadarVerifiedLocationToken *obj) { return obj.passed; }
RADAR_API_SURFACE NSArray<NSString *> *_Nullable get_RadarVerifiedLocationToken_failureReasons(RadarVerifiedLocationToken *obj) { return obj.failureReasons; }
RADAR_API_SURFACE NSString *_Nullable get_RadarVerifiedLocationToken__id(RadarVerifiedLocationToken *obj) { return obj._id; }
RADAR_API_SURFACE NSDictionary *_Nullable get_RadarVerifiedLocationToken_fullDict(RadarVerifiedLocationToken *obj) { return obj.fullDict; }
RADAR_API_SURFACE NSDictionary *_Nonnull call_RadarVerifiedLocationToken_dictionaryValue(RadarVerifiedLocationToken *obj) { return [obj dictionaryValue]; }
