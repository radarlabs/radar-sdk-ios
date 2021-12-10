//  Copyright © 2021 Radar Labs, Inc. All rights reserved.

import Foundation

public extension Radar {

    /// The SDK version number, taken from the bundle's
    /// `CFBundleShortVersionString`.
    @objc class var sdkVersion: String {
        let bundle = Bundle(for: Radar.self)
        let key = "CFBundleShortVersionString"

        guard let marketingVersion = bundle.object(forInfoDictionaryKey: key) as? String else {
            return "unknown"
        }

        return marketingVersion
    }

}
