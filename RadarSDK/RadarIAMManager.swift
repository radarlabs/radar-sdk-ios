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
    
//    public static var delegate: RadarIAMDelegate_ObjC = RadarIAMDelegate_ObjC()
    
    @objc public static func showInAppMessage(_ message: RadarInAppMessage) async {
        guard let currentWindowScene = UIApplication.shared.connectedScenes.first as?  UIWindowScene else {
            print("no current window scene")
            return
        }
        
        let overlayWindow = UIWindow(windowScene: currentWindowScene)
        overlayWindow.windowLevel = UIWindow.Level.alert
        overlayWindow.backgroundColor = .clear
        
//        let view = delegate.getIAMViewController(message)
//        overlayWindow.frame = view.view.frame
//        overlayWindow.layer.position = view.view.layer.position
        
//        overlayWindow.rootViewController = view
        overlayWindow.isHidden = false
//        overlayWindow.makeKeyAndVisible()
        
        window = overlayWindow
    }
    
    @objc public static func enableIAM() {
        
    }
    
    @objc public static func onIAMReceived(message: RadarInAppMessage) {
        if suppressed {
            // goes to queue
            message.receivedLive = false
            messageQueue.append(message)
        } else {
            // show
            showingMessages.append(contentsOf: messageQueue)
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
        window?.isHidden = true
        window?.rootViewController = nil
        window?.removeFromSuperview()
        window = nil
        
        if !messageQueue.isEmpty && !suppressed {
            let message = messageQueue.removeFirst()
            Task {
                await showInAppMessage(message)
            }
        }
    }
    
//    @objc public static func setDelegate(_ delegate: RadarIAMDelegate_ObjC) {
//        self.delegate = delegate
//        print("DELEGATE SET!")
//    }
}
