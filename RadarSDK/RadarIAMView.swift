//
//  RadarInAppMessageView.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/10/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct RadarIAMView: View {
    var message: RadarInAppMessage
    var image: UIImage?
    
    
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image).resizable(capInsets: .init())
            }
            
            Button(action: {
                RadarIAMManager.dismissInAppMessage()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.secondary)
                    .font(.system(size: 20))
            })
            .frame(width: 200, height: 200, alignment: .topTrailing)
            
            
            VStack {
                Text(message.title?.text ?? "").foregroundColor(Color(message.title?.color ?? UIColor.black))
                Text(message.body?.text ?? "").foregroundColor(Color(message.body?.color ?? UIColor.black))
                Button(message.action?.text ?? "") {
                    RadarIAMManager.delegate.onIAMPositiveAction(message)
                    RadarIAMManager.dismissInAppMessage()
                }.foregroundColor(Color(message.action?.color ?? UIColor.black))
                 .background(Color(message.action?.backgroundColor ?? UIColor.white))
            }
        }.frame(width: 200, height: 200)
    }
}

@available(iOS 13.0, *)
#Preview {
    RadarIAMView(message: RadarInAppMessage.fromDictionary(dict:[
        "type": "banner",
        "title": [
            "text": "This is the title",
            "color": "ff00007f"
        ],
        "body": [
            "text": "This is a demo message.",
            "color": "00ff00ff"
        ],
        "action": [
            "text": "Buy it",
            "color": "0000ffff",
            "backgroundColor": "ffffffff",
        ],
        "imageURL": "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg",
    ]))
}
