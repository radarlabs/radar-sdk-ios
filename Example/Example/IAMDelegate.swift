//
//  IAMDelegate.swift
//  Example
//
//  Created by ShiCheng Lu on 7/22/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import RadarSDK
import SwiftUICore


class MyIAMDelegate: RadarInAppMessageDelegate {
    override func onInAppMessageButtonClicked(_ message: RadarInAppMessage) {
        if let url = message.button?.url {
            UIApplication.shared.open(URL(string: url)!)
        }
        print("custom on IAM positive action")
        // possibly log conversion
    }
}

