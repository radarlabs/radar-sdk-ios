//
//  RadarReplay.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/29/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarReplay)
@objcMembers
internal class RadarReplay: NSObject, NSSecureCoding {

    public let replayParams: [AnyHashable: Any]

    @objc(initWithParams:)
    public init(params: [AnyHashable: Any]) {
        self.replayParams = params
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let params = coder.decodeObject(forKey: "replayParams") as? [AnyHashable: Any] else {
            return nil
        }
        self.replayParams = params
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(replayParams, forKey: "replayParams")
    }

    @objc(arrayForReplays:)
    public static func arrayForReplays(_ replays: [RadarReplay]?) -> [[AnyHashable: Any]]? {
        guard let replays = replays else {
            return nil
        }
        return replays.map { $0.replayParams }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if self === object as? RadarReplay {
            return true
        }
        guard let other = object as? RadarReplay else {
            return false
        }
        return (replayParams as NSDictionary).isEqual(to: other.replayParams)
    }

    public override var hash: Int {
        return (replayParams as NSDictionary).hash
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
}
