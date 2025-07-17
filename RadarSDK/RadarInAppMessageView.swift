//
//  RadarInAppMessageView.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/10/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct RadarInAppMessageView: View {
    var config: RadarInAppMessageConfig? 
    
    var body: some View {
        ZStack {
        
            if #available(iOS 14.0, *) {
                Color.red.opacity(0.2)
            } else {
                Color.red.opacity(0.2)
            }
            
            if #available(iOS 15.0, *) {
                AsyncImage(url: URL(string: "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg")!) { image in
                    image.resizable()
                } placeholder: {
                    Color.clear
                }
            } else {
                // Fallback on earlier versions
            }
            
            VStack {
                Text(config?.title ?? "")
                Text(config?.body ?? "").font(Font.custom(config?.font ?? "", size: -1))
                Button("close") {
                    RadarInAppMessage.dismissInAppMessage()
                }
            }
        }
    }
}

@available(iOS 13.0, *)
#Preview {
    RadarInAppMessageView(config: RadarInAppMessageConfig.fromDictionary(dict:[
        "title": "TEST TITLE",
        "body": "TEST BODY",
        "type": "banner",
        "font": "papyrus"
    ]))
}
