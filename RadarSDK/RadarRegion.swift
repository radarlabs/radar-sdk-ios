//
//  RadarRegion.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a region.
///
/// - SeeAlso: https://radar.com/documentation/regions
@objc(RadarRegion)
@objcMembers
public final class RadarRegion: NSObject {
    /// The Radar ID of the region.
    public let _id: String  // swiftlint:disable:this identifier_name

    /// The name of the region.
    public let name: String

    /// The unique code for the region.
    public let code: String

    /// The type of the region.
    public let type: String

    /// The optional flag of the region.
    public let flag: String?

    /// A boolean indicating whether the jurisdiction is allowed. May be `false` if Fraud is not enabled.
    public let allowed: Bool

    /// A boolean indicating whether all jurisdiction checks for the region have passed. May be `false` if Fraud is not enabled.
    public let passed: Bool

    /// A boolean indicating whether the user is in an exclusion zone for the jurisdiction. May be `false` if Fraud is not enabled.
    public let inExclusionZone: Bool

    /// A boolean indicating whether the user is too close to the border for the jurisdiction. May be `false` if Fraud is not enabled.
    public let inBufferZone: Bool

    /// The distance in meters to the border of the jurisdiction. May be 0 if Fraud is not enabled.
    public let distanceToBorder: Double

    /// A boolean indicating whether the jurisdiction is expected based on the values passed to `setExpectedJurisdiction()`.
    public let expected: Bool

    override convenience init() {
        self.init(
            id: "", name: "", code: "", type: "", flag: nil, allowed: false, passed: false,
            inExclusionZone: false, inBufferZone: false, distanceToBorder: 0, expected: false)
    }

    // Keeps the Objective-C initializer declared in RadarRegion+Internal.h working.
    @objc(initWithId:name:code:type:flag:allowed:passed:inExclusionZone:inBufferZone:distanceToBorder:expected:)
    init(
        id: String,
        name: String,
        code: String,
        type: String,
        flag: String?,
        allowed: Bool,
        passed: Bool,
        inExclusionZone: Bool,
        inBufferZone: Bool,
        distanceToBorder: Double,
        expected: Bool
    ) {
        self._id = id
        self.name = name
        self.code = code
        self.type = type
        self.flag = flag
        self.allowed = allowed
        self.passed = passed
        self.inExclusionZone = inExclusionZone
        self.inBufferZone = inBufferZone
        self.distanceToBorder = distanceToBorder
        self.expected = expected
        super.init()
    }

    // Keeps the hand-written Objective-C parser working for existing SDK callers. Like the
    // Objective-C parser, any dictionary produces a region: missing strings default to "" (including
    // `flag`), and missing booleans and numbers default to false and 0.
    @objc(initWithObject:)
    convenience init?(object: Any?) {
        guard let dict = object as? NSDictionary else {
            return nil
        }

        func bool(_ key: String) -> Bool {
            (dict[key] as? NSNumber)?.boolValue ?? false
        }

        self.init(
            id: dict["_id"] as? String ?? "",
            name: dict["name"] as? String ?? "",
            code: dict["code"] as? String ?? "",
            type: dict["type"] as? String ?? "",
            flag: dict["flag"] as? String ?? "",
            allowed: bool("allowed"),
            passed: bool("passed"),
            inExclusionZone: bool("inExclusionZone"),
            inBufferZone: bool("inBufferZone"),
            distanceToBorder: (dict["distanceToBorder"] as? NSNumber)?.doubleValue ?? 0,
            expected: bool("expected")
        )
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "_id": _id,
            "name": name,
            "code": code,
            "type": type,
            "allowed": allowed,
            "passed": passed,
            "inExclusionZone": inExclusionZone,
            "inBufferZone": inBufferZone,
            "distanceToBorder": distanceToBorder,
            "expected": expected,
        ]
        if let flag {
            dict["flag"] = flag
        }
        return dict
    }
}
