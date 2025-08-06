//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
@objc
public
class RadarInAppMessageManager: NSObject {
    private static var window: UIWindow? = nil
    private static var messageQueue: [RadarInAppMessage] = []
    private static var suppressed: Bool = false
    private static var showingMessages: [RadarInAppMessage] = []
    private static var displayTimer: Timer? = nil
    
    public static var delegate: RadarInAppMessageProtocol = RadarInAppMessageDelegate()
    public static var view: UIView?
    
    @objc public static func showInAppMessage(_ message: RadarInAppMessage) async {
        // check before getting the view that there is no existing IAM shown
        if (view != nil) {
            return
        }
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            // No key window
            return
        }
        
        let viewController = await withCheckedContinuation { continuation in
            delegate.createInAppMessageView(message) { result in
                continuation.resume(returning: result)
            }
        }
        // check after getting the view asynchronously that there is no existing IAM shown
        if (view != nil) {
            return
        }
        view = viewController.view
        viewController.view.frame = UIScreen.main.bounds
        viewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        keyWindow.addSubview(viewController.view)
    }
    
    @objc public static func onInAppMessageReceived(messages: [RadarInAppMessage]) {
        for message in messages {
            if (delegate.onNewInAppMessage(message) == RadarInAppMessageOperation.show) {
                Task {
                    await showInAppMessage(message)
                }
                break
            }
        }
    }
    
    @objc public static func dismissInAppMessage() {
        view?.removeFromSuperview()
        view = nil
    }
    
    @objc public static func setDelegate(_ delegate: RadarInAppMessageProtocol) {
        self.delegate = delegate
    }
}
