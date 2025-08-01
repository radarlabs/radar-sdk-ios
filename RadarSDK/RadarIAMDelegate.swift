//
//  RadarIAMDelegate.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/22/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
func loadImage(_ url: String) async -> UIImage? {
    if (url.isEmpty) {
        return nil
    }
    
    let image: UIImage? = await withCheckedContinuation { continuation in
        URLSession.shared.dataTask(with: URL(string: url)!) {
            data, response, error in
            guard let data = data else {
                continuation.resume(returning: nil)
                return
            }
            guard let image = UIImage(data: data) else {
                continuation.resume(returning: nil)
                return
            }
            continuation.resume(returning: image)
        }.resume()
    }
    return image
}


@available(iOS 13.0, *)
@objc(RadarIAMDelegate_Swift)
@objcMembers
open class RadarIAMDelegate : RadarIAMDelegate_ObjC {
    /**
     returns the view controller for the message to show, can be overwritten to display a custom view
     */
    open override func getIAMViewController(_ message: RadarInAppMessage, completionHandler: @escaping (UIViewController) -> Void) {
        Task {
            var image: UIImage? = nil
            if let imageUrl = message.image?.url {
                image = await loadImage(imageUrl)
            }
            let viewController = UIHostingController(rootView: RadarIAMView(message: message, image: image))
            completionHandler(viewController)
        }
    }
    
    open override func onIAMPositiveAction(_ message: RadarInAppMessage) {
        if let url = message.button?.url {
            UIApplication.shared.open(URL(string: url)!)
        }
        print("onIAMPositiveAction")
    }
    
    open override func onNewMessage(_ message: RadarInAppMessage) -> RadarIAMResponse {
        return .show
    }
}


