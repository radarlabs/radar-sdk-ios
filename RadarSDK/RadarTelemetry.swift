//
//  RadarProfiler.swift
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarTelemetry) class RadarTelemetry: NSObject {
    
    var startTimes = [String:Double]()
    var endTimes = [String:Double]()
    
    @objc func start(_ tag: String = "") {
        startTimes[tag] = CFAbsoluteTimeGetCurrent()
    }
    
    @objc func end(_ tag: String = "") {
        if (startTimes[tag] != nil) {
            endTimes[tag] = CFAbsoluteTimeGetCurrent()
        }
    }
    
    @objc func get(_ tag: String = "") -> Double {
        if let start = startTimes[tag],
           let end = endTimes[tag] {
            return (end - start)
        } else {
            return 0;
        }
    }
    
    @objc func formatted() -> String {
        return endTimes.map { (tag, end) in
            String(format: "%@: %.3f", tag, end - startTimes[tag]!)
        }.joined(separator: ", ")
    }
}
