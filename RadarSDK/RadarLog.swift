//
//  RadarLog.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

class RadarLog {
    static func levelFromString(string: String?) -> RadarLogLevel {
        if (string == "none") {
            return .none;
        } else if (string == "error") {
            return .error;
        } else if (string == "warning") {
            return .warning;
        } else if (string == "info") {
            return .info;
        } else if (string == "debug") {
            return .debug;
        } else {
            return .info;
        }
    }
    
    // TODO: other functions
}

extension RadarLogLevel {
    func toString() -> String {
        switch self {
            case .none:
                return "none";
            case .error:
                return "error";
            case .warning:
                return "warning";
            case .info:
                return "info";
            case .debug:
                return "debug";
            @unknown default:
                return "info";
        }
    }
    
    static func fromString(_ value: String?) -> RadarLogLevel {
        if (value == "none") {
            return .none;
        } else if (value == "error") {
            return .error;
        } else if (value == "warning") {
            return .warning;
        } else if (value == "info") {
            return .info;
        } else if (value == "debug") {
            return .debug;
        } else {
            return .info;
        }
    }
}
