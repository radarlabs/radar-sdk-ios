//
//  MyIAMDelegate.swift
//  Example
//
//  Created by ShiCheng Lu on 12/18/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import RadarSDK

class MyIAMDelegate: RadarInAppMessageDelegate {
    override func createInAppMessageView(_ message: RadarInAppMessage, onDismiss: @escaping () -> Void, onInAppMessageClicked: @escaping () -> Void, completionHandler: @escaping (UIViewController) -> Void) {
        guard let message = message as? RadarInAppMessage_Swift else {
            return
        }
        message.body.text = message.body.text + " {Loyal User}!"
        super.createInAppMessageView(message, onDismiss: onDismiss, onInAppMessageClicked: onInAppMessageClicked, completionHandler: completionHandler)
    }
    
    override func onInAppMessageButtonClicked(_ message: RadarInAppMessage) {
        print("IAM CLICKED")
    }

    override func onInAppMessageDismissed(_ message: RadarInAppMessage) {
        print("IAM DISMISSED")
    }
}

