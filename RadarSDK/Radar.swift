//  Copyright © 2021 Radar Labs, Inc. All rights reserved.

import Foundation

public extension Radar {

    /// The SDK version number, taken from the bundle's
    /// `CFBundleShortVersionString`.
    @objc class var sdkVersion: String {
        guard let marketingVersion =  Bundle(for: Radar.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return "unknown"
        }

        return marketingVersion
    }

}
