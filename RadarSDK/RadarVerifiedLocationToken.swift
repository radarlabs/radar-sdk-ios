//
//  RadarVerifiedLocationToken.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/9/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarVerifiedLocationToken) @objcMembers
class RadarVerifiedLocationToken: NSObject {
    let user: RadarUser?
    let events: [RadarEvent]?
    let token: String?
    let expiresAt: Date?
    let expiresIn: TimeInterval
    let passed: Bool
    let failureReasons: [String]
    @objc(_id)
    let id: String?
    let fullDict: [String: Any]
    
    func dictionaryValue() -> [String: Any] {
        return fullDict
    }
    
    init?(with object: Any) {
        guard let dict = object as? [String: Any] else {
            return nil
        }
        
        guard let userDict = dict["user"],
              let user = RadarUser(object: userDict) else {
            return nil
        }
        guard let eventsArray = dict["events"] as? [[String: Any]],
              let events = eventsArray.map({ RadarSwift.bridge?.createEvent(dict: $0) }) as? [RadarEvent] else {
            return nil
        }
        guard let expiresAtString = dict["expiresAt"] as? String,
              let expiresAt = RadarUtils.isoDateFormatter.date(from: expiresAtString) else {
            return nil
        }
        guard let token = dict["token"] as? String else {
            return nil
        }
        
        let expiresIn = dict["expiresIn"] as? TimeInterval ?? 0
        let passed = dict["passed"] as? Bool ?? false
        let id = dict["id"] as? String ?? ""
        let failureReasons = dict["failureReasons"] as? [String]
        
        
        self.user = user
        self.events = events
        self.expiresAt = expiresAt
        self.expiresIn = expiresIn
        self.passed = passed
        self.token = token
        self.id = id
        self.failureReasons = failureReasons ?? []
        self.fullDict = dict
    }
}
