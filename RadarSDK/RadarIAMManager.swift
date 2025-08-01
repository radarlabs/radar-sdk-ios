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
        // check before getting the view that there is no existing IAM shown
        if (view != nil) {
            return
        }
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            // No key window
            return
        }
        
        let viewController = await withCheckedContinuation { continuation in
            delegate.getIAMViewController(message) { result in
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
    
    @objc public static func onIAMReceived(messages: [RadarInAppMessage]) {
        print("IAM received")
        for message in messages {
            if (delegate.onNewMessage(message) == RadarIAMResponse.show) {
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
    
    @objc public static func setDelegate(_ delegate: RadarIAMDelegate_ObjC) {
        self.delegate = delegate
    }
}
