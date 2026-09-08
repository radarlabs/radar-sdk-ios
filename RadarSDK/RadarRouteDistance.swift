//
//  RadarRouteDistance.swift
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarRouteDistance)
@objcMembers
final class RadarRouteDistance: NSObject {
    let value: Double
    let text: String

    override init() {
        value = 0
        text = ""
        super.init()
    }

    /// Keeps the hand-written Objective-C initializer working after the implementation moved to Swift.
    @objc(initWithValue:text:)
    init(value: Double, text: String) {
        self.value = value
        self.text = text
        super.init()
    }

    /// Keeps the hand-written Objective-C parser working for existing SDK callers.
    /// A missing or non-numeric `value` falls back to 0, but a missing `text` rejects the payload.
    @objc(initWithObject:)
    init?(object: Any) {
        guard let dictionary = object as? NSDictionary,
            let text = dictionary["text"] as? String
        else {
            return nil
        }

        self.value = (dictionary["value"] as? NSNumber)?.doubleValue ?? 0
        self.text = text
        super.init()
    }

    func dictionaryValue() -> [String: Any] {
        [
            "value": value,
            "text": text,
        ]
    }
}
