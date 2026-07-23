//
//  RadarDelegateHolder.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@globalActor
public actor RadarDelegateActor {
    public static let shared = RadarDelegateActor()
}

@RadarDelegateActor
@objc(RadarDelegateHolder_Swift)
public class RadarDelegateHolder: NSObject {

    // Routes through RadarSwiftBridge to the ObjC RadarDelegateHolder singleton, which owns the
    // app's delegate (set via Radar.setDelegate). This is the single source of truth — do not
    // reintroduce a separate delegate here, or these updates will silently never reach the app.
    static func didUpdateClientLocation(location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        RadarSwift.bridge?.didUpdateClientLocation(location, stopped: stopped, source: source)
    }
}
