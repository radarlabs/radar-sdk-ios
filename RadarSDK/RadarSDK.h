//
//  RadarSDK.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for RadarSDK.
FOUNDATION_EXPORT double RadarSDKVersionNumber;

//! Project version string for RadarSDK.
FOUNDATION_EXPORT const unsigned char RadarSDKVersionString[];

#import "Radar.h"
#import "RadarAddress.h"
#import "RadarChain.h"
#import "RadarCircleGeometry.h"
#import "RadarCoordinate.h"
#import "RadarDelegate.h"
#import "RadarEvent.h"
#import "RadarGeofence.h"
#import "RadarGeofenceGeometry.h"
#import "RadarPlace.h"
#import "RadarPolygonGeometry.h"
#import "RadarRegion.h"
#import "RadarRoute.h"
#import "RadarRouteDistance.h"
#import "RadarRouteDuration.h"
#import "RadarRouteGeometry.h"
#import "RadarRouteMode.h"
#import "RadarRoutes.h"
#import "RadarTrackingOptions.h"
#import "RadarTrip.h"
#import "RadarTripOptions.h"
#import "RadarTripOrder.h"
#import "RadarUser.h"
#import "RadarVerifiedDelegate.h"
#import "RadarMotionProtocol.h"
#import "RadarSdkConfiguration.h"
#import "RadarInAppMessage.h"
#import "RadarInAppMessageDelegate.h"
#import "Radar-Swift.h"
#import "RadarIndoorsProtocol.h"

// Internal headers (exposed for Swift interop within the framework)
#import "RadarLocationProviding.h"
#import "RadarLocationManager.h"
#import "RadarPermissionsHelper.h"
#import "RadarActivityManager.h"
#import "RadarState.h"
#import "RadarSettings.h"
#import "RadarDelegateHolder.h"
#import "RadarLogger.h"
#import "RadarMeta.h"
#import "RadarUtils.h"
#import "RadarBeaconManager.h"
#import "RadarReplayBuffer.h"
#import "RadarNotificationHelper.h"
#import "CLLocation+Radar.h"
#import "Radar+Internal.h"
