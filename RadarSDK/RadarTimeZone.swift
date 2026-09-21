//
//  RadarTimeZone.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @implementation extension RadarTimeZone {
    /// Keep one formatter to preserve the legacy wire format and POSIX locale.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    // The underscore is part of the public Objective-C property name.
    // swiftlint:disable:next identifier_name
    @objc(_id) var _id: String! = nil
    var name: String! = nil
    var code: String! = nil
    private var currentTimeStorage: Any?
    var currentTime: Date! {
        currentTimeStorage as? Date
    }
    var utcOffset: Int32 = 0
    var dstOffset: Int32 = 0

    override init() {
        super.init()
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]
        if let id = _id as String? {
            dictionary["id"] = id
        }
        if let name = name as String? {
            dictionary["name"] = name
        }
        if let code = code as String? {
            dictionary["code"] = code
        }
        if let currentTime = currentTime as Date? {
            dictionary["currentTime"] = Self.dateFormatter.string(from: currentTime)
        }
        dictionary["utcOffset"] = NSNumber(value: utcOffset)
        dictionary["dstOffset"] = NSNumber(value: dstOffset)
        return dictionary
    }
}

extension RadarTimeZone {
    var id: String? { _id }

    /// Keeps the hand-written Objective-C header's `initWithObject:` selector working.
    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dictionary = object as? NSDictionary else {
            return nil
        }

        self.init()
        _id = dictionary["id"] as? String
        name = dictionary["name"] as? String
        code = dictionary["code"] as? String
        if let currentTimeString = dictionary["currentTime"] as? String {
            currentTimeStorage = Self.dateFormatter.date(from: currentTimeString)
        } else {
            currentTimeStorage = nil
        }
        utcOffset = (dictionary["utcOffset"] as? NSNumber)?.int32Value ?? 0
        dstOffset = (dictionary["dstOffset"] as? NSNumber)?.int32Value ?? 0
    }

}
