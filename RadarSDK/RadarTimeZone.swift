//
//  RadarTimeZone.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarTimeZone)
@objcMembers
final class RadarTimeZone: NSObject {
    /// Keep one formatter to preserve the legacy wire format and POSIX locale.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    @objc(_id) let id: String?
    let name: String?
    let code: String?
    let currentTime: Date?
    let utcOffset: Int32
    let dstOffset: Int32

    override init() {
        id = nil
        name = nil
        code = nil
        currentTime = nil
        utcOffset = 0
        dstOffset = 0
        super.init()
    }

    /// Keeps the hand-written Objective-C header's `initWithObject:` selector working.
    @objc(initWithObject:)
    init?(object: Any) {
        guard let dictionary = object as? NSDictionary else {
            return nil
        }

        id = dictionary["id"] as? String
        name = dictionary["name"] as? String
        code = dictionary["code"] as? String
        if let currentTimeString = dictionary["currentTime"] as? String {
            currentTime = Self.dateFormatter.date(from: currentTimeString)
        } else {
            currentTime = nil
        }
        utcOffset = (dictionary["utcOffset"] as? NSNumber)?.int32Value ?? 0
        dstOffset = (dictionary["dstOffset"] as? NSNumber)?.int32Value ?? 0
        super.init()
    }

    func dictionaryValue() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        if let id {
            dictionary["id"] = id
        }
        if let name {
            dictionary["name"] = name
        }
        if let code {
            dictionary["code"] = code
        }
        if let currentTime {
            dictionary["currentTime"] = Self.dateFormatter.string(from: currentTime)
        }
        dictionary["utcOffset"] = NSNumber(value: utcOffset)
        dictionary["dstOffset"] = NSNumber(value: dstOffset)
        return dictionary
    }
}
