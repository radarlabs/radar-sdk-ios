//
//  MyIAMDelegate.swift
//  Example
//
//  Created by ShiCheng Lu on 12/18/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import RadarSDK

class MyIAMDelegate: RadarInAppMessageDelegate {
    private let logStream: LogStream

    init(logStream: LogStream) {
        self.logStream = logStream
        super.init()
    }

    override func createInAppMessageView(
        _ message: RadarInAppMessage, onDismiss: @escaping () -> Void, onInAppMessageClicked: @escaping () -> Void, completionHandler: @escaping (UIViewController) -> Void
    ) {
        guard let message = message as? RadarInAppMessage_Swift else {
            return
        }
        message.body.text = message.body.text + " {Loyal User}!"
        super.createInAppMessageView(message, onDismiss: onDismiss, onInAppMessageClicked: onInAppMessageClicked, completionHandler: completionHandler)
    }

    override func onInAppMessageButtonClicked(_ message: RadarInAppMessage) {
        logStream.write(result: "IAM clicked")
    }

    override func onInAppMessageDismissed(_ message: RadarInAppMessage) {
        logStream.write(result: "IAM dismissed")
    }
}
