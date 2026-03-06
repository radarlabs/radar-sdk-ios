//
//  RadarDelegateHolder.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

@globalActor
@available(iOS 13.0, *)
public actor RadarDelegateActor {
    public static let shared = RadarIndoorsActor()
}

@RadarDelegateActor
@available(iOS 13.0, *)
@objc(RadarDelegateHolder_Swift)
public class RadarDelegateHolder: NSObject {
    
    @objc
    public static var delegate: RadarDelegate?
    
    static func didUpdateClientLocation(location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        delegate?.didUpdateClientLocation?(location, stopped: stopped, source: source)
    }
}
