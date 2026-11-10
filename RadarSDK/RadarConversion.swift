//
//  RadarConversion.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a conversion logged with `Radar.logConversion`.
@objc(RadarConversion)
@objcMembers
public final class RadarConversion: NSObject {
    /// The Radar ID of the conversion.
    public let _id: String  // swiftlint:disable:this identifier_name

    /// The name of the conversion, as passed to `Radar.logConversion`.
    public let name: String

    /// The datetime when the conversion occurred on the device.
    public let createdAt: Date

    /// The datetime when the conversion was created on the server. May be `nil` if the server did not return it.
    public let actualCreatedAt: Date?

    /// A boolean indicating whether the conversion was logged with your live API key.
    public let live: Bool

    /// The metadata of the conversion. May be `nil` if the conversion had no metadata.
    public let metadata: [AnyHashable: Any]?

    // There is no `init()`, so `RadarConversion()` and `[RadarConversion new]` aren't public API.

    // Parses the `event` object of a `POST /v1/events` response. Returns nil for a non-dictionary,
    // or a missing `_id`, `createdAt`, or `type`. Wrongly typed optional fields are ignored.
    @objc(initWithObject:)
    init?(object: Any?) {
        guard let dict = object as? NSDictionary,
            let id = dict["_id"] as? String,
            let name = dict["type"] as? String,
            let createdAt = RadarEventParsing.date(from: dict["createdAt"])
        else {
            return nil
        }

        _id = id
        self.name = name
        self.createdAt = createdAt
        actualCreatedAt = RadarEventParsing.date(from: dict["actualCreatedAt"])
        live = (dict["live"] as? NSNumber)?.boolValue ?? false
        metadata = RadarEventParsing.metadata(from: dict["metadata"])
        super.init()
    }

    // Keeps the keys that `RadarEvent.dictionaryValue()` wrote for a conversion, including
    // `"type": "custom"`, so hybrid SDK wrappers keep working. Adds `name`.
    public func dictionaryValue() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        dict["_id"] = _id
        dict["type"] = RadarEvent.string(for: .conversion)
        dict["name"] = name
        dict["live"] = live
        dict["metadata"] = metadata
        dict["createdAt"] = RadarUtils.isoDateFormatter.string(from: createdAt)
        dict["actualCreatedAt"] = actualCreatedAt.map { RadarUtils.isoDateFormatter.string(from: $0) }
        return dict
    }
}
