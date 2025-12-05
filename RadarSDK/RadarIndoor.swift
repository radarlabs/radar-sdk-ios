//
//  RadarIndoor.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/2/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

protocol RadarSDKIndoorsInterface {
    public static func start(uuids: Set<UUID>) async
    public static func useModel(model: String, getModelData: @escaping () async -> Data?) async
    public static func getLocation(): (x: Double, y: Double)?
    public static func stop()
}


class RadarIndoors {
    let shared = RadarIndoors()
    
    let site: RadarSite?
    
    public func start(site: RadarSite) {
        self.site = site
        
        guard let RadarSDKIndoors = NSClassFromString("RadarSDKIndoors") as? RadarSDKIndoorsInterface.Type {
            return
        }
        // download the ml model
        RadarAPIClient.shared.getAsset(url: site.url) { (result) in
            
        }
        
        // start ranging the beacons
        let uuids = Set(site.beacons.map(\.uuid))
        RadarSDKIndoors.start(uuids: uuids);
    }
    
    public async func getLocation() {
        guard let RadarSDKIndoors = NSClassFromString("RadarSDKIndoors") as? RadarSDKIndoorsInterface.Type {
            return
        }
        await RadarSDKIndoors.getLocation()
        
    }
}
