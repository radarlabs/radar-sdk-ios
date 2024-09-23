//
//  RadarLog.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/23/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation


@objc public class RadarLog: NSObject {
    /**
     The levels for debug logs.
     */
    @objc public let level: RadarLogLevel;

    /**
     The log message.
     */
    @objc public let message: NSString;

    /**
     The log type.
     */
    @objc public let type: RadarLogType;

    /**
     The datetime when the log occurred on the device.
     */
    @objc public let createdAt: NSDate;

    @objc public init(level: RadarLogLevel, type: RadarLogType, message: NSString, createdAt: NSDate) {
        self.level = level
        self.message = message
        self.type = type
        self.createdAt = createdAt
    }
    
    @objc public func dictionaryValue() -> Dictionary<String, Any> {
        var dict = [String:Any]()
        
        dict["level"] = RadarLog.stringForLogLevel(level)
        dict["message"] = message
        dict["type"] = RadarLog.stringForLogType(type)
        dict["createdAt"] = RadarUtils.isoDateFormatter.string(from: createdAt as Date)
        return dict;
    }

    
    @objc public static func arrayForLogs(_ logs: Array<RadarLog>?) -> Array<Dictionary<String, Any>>? {
        guard let logs = logs else {
            return nil;
        }

        var array = [[String:Any]]()
        array.reserveCapacity(logs.count)
        
        for log in logs {
            array.append(log.dictionaryValue())
        }
        return array;
    }
    
    /**
      Returns a display string for a log type.

      @param type A log type

      @return A display string for the log type.
     */
    @objc public static func stringForLogType(_ type: RadarLogType) -> String {
        switch (type) {
        case RadarLogType.none:
            return "NONE";
        case RadarLogType.sdkCall:
            return "SDK_CALL";
        case RadarLogType.sdkError:
            return "SDK_ERROR";
        case RadarLogType.sdkException:
            return "SDK_EXCEPTION";
        case RadarLogType.appLifecycleEvent:
            return "APP_LIFECYCLE_EVENT";
        case RadarLogType.permissionEvent:
            return "PERMISSION_EVENT";
        @unknown default:
            return "UNKNOWN";
        }
    }
    
    /**
     Returns a display string for a log level.

     @param level A log level

     @return A display string for the log level.
     */
    @objc public static func stringForLogLevel(_ level: RadarLogLevel) -> String {
        switch (level) {
        case RadarLogLevel.none:
            return "none";
        case RadarLogLevel.error:
            return "error";
        case RadarLogLevel.warning:
            return "warning";
        case RadarLogLevel.info:
            return "info";
        case RadarLogLevel.debug:
            return "debug";
        @unknown default:
            return "unkown";
        }
    }
    
    /**
     Return the log level for a specific display string
     
     @param string A display string for the log level

     @return A log level.
    */
    @objc public static func levelFromString(_ string: String) -> RadarLogLevel {
        let string = string.lowercased();
        if (string == "none") {
            return RadarLogLevel.none;
        } else if (string == "error") {
            return RadarLogLevel.error;
        } else if (string == "warning") {
            return RadarLogLevel.warning;
        } else if (string == "info") {
            return RadarLogLevel.info;
        } else if (string == "debug") {
            return RadarLogLevel.debug;
        } else {
            return RadarLogLevel.info;
        }
    }

}
