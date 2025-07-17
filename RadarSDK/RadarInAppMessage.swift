//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/10/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
@objc
public
class RadarInAppMessage: NSObject {
    @MainActor private static var overlayWindow: UIWindow? = nil
    
    @MainActor @objc public static func showInAppMessage(config: RadarInAppMessageConfig) {
        guard let currentWindowScene = UIApplication.shared.connectedScenes.first as?  UIWindowScene else {
            print("no current window scene")
            return
        }
        
        let overlayWindow = UIWindow(windowScene: currentWindowScene)
        overlayWindow.windowLevel = UIWindow.Level.alert
        overlayWindow.frame = overlayWindow.frame.insetBy(dx:30, dy:30)
        
        let newController = UIHostingController(rootView: RadarInAppMessageView(config: config))
        overlayWindow.rootViewController = newController
        overlayWindow.makeKeyAndVisible()
        
        self.overlayWindow = overlayWindow
        
    }
    
    @MainActor @objc public static func dismissInAppMessage() {
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow?.removeFromSuperview()
        overlayWindow = nil
    }
}
