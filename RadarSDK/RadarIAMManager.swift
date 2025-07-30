//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/10/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
@objc
public
class RadarIAMManager: NSObject {
    private static var window: UIWindow? = nil
    private static var messageQueue: [RadarInAppMessage] = []
    private static var suppressed: Bool = false
    private static var showingMessages: [RadarInAppMessage] = []
    private static var displayTimer: Timer? = nil
    
    public static var delegate: RadarIAMDelegate_ObjC = RadarIAMDelegate_ObjC()
    public static var view: UIView?
    
    @objc public static func showInAppMessage(_ message: RadarInAppMessage) async {
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            // No key window
            return
        }
        
        let viewController = await withCheckedContinuation { continuation in
            delegate.getIAMViewController(message) { result in
                continuation.resume(returning: result)
            }
        }
        if (view != nil) {
            return
        }
        view = viewController.view
        viewController.view.frame = UIScreen.main.bounds
        viewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        keyWindow.addSubview(viewController.view)
    }
    
    @objc public static func enableIAM() {
        
    }
    
    @objc public static func onIAMReceived(message: [RadarInAppMessage]) {
        print("IAM received")
        if suppressed {
            // goes to queue
//            message.receivedLive = false
            messageQueue.append(contentsOf: message)
        } else {
            // show
            showingMessages.append(contentsOf: message)
            if (!showingMessages.isEmpty) {
                Task {
                    await showInAppMessage(showingMessages.first!)
                }
            }
        }
        
        
    }
    
    @objc public static func suppressIAM() {
        suppressed = true
        // cancel any active view
        dismissInAppMessage()
    }
    
    @objc public static func unsuppressIAM() {
        suppressed = false
        
    }
    
    @objc public static func dismissInAppMessage() {
        view?.removeFromSuperview()
        view = nil
        
        if !messageQueue.isEmpty && !suppressed {
            let message = messageQueue.removeFirst()
            Task {
                await showInAppMessage(message)
            }
        }
    }
    
    @objc public static func setDelegate(_ delegate: RadarIAMDelegate_ObjC) {
        self.delegate = delegate
    }
}
