//
//  RadarInAppMessageView.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct RadarIAMView: View {
    var message: RadarInAppMessage
    var image: UIImage?
    var onDismiss: (() -> Void)
    var onInAppMessageClicked: (() -> Void)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable(capInsets: .init())
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 350, maxHeight: 200)
                        .clipped()
                } else {
                    Spacer().frame(width: 350, height: 50)
                }
                VStack {
                    // Title
                    Text(message.title.text)
                        .foregroundColor(Color(message.title.color))
                        .font(Font.system(size: 32, weight: .bold))

                    // Body
                    Text(message.body.text)
                        .foregroundColor(Color(message.body.color))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 310)
                        .padding(.top, 5)
                        .padding(.bottom, 15)
                        .font(Font.system(size: 17, weight: .regular))

                    // Button
                    if (message.button != nil) {
                        Button(action: {
                            onInAppMessageClicked()
                        }) {
                            Text(message.button?.text ?? "")
                                .frame(width: 310, height: 50)
                                .foregroundColor(Color(message.button?.color ?? UIColor.black))
                                .background(Color(message.button?.backgroundColor ?? UIColor.white))
                                .cornerRadius(10)
                                .font(Font.system(size: 22, weight: .bold))
                        }
                    }
                }.padding(.bottom, 20)
            }.background(Color.white).cornerRadius(20)

            // Close button
            Button(action: {
                onDismiss()
            }, label: {
                ZStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 30))
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .bold))
                }
            })
            .padding(10)
        }
    }
}

@available(iOS 13.0, *)
#Preview {
    ZStack {
        Color.blue
        RadarIAMView(message: RadarInAppMessage.fromDictionary([
                "type": "banner",
                "title": [
                    "text": "This is the title",
                    "color": "#000000"
                ],
                "body": [
                    "text": "This is a demo message",
                    "color": "#666666"
                ],
                "button": [
                    "text": "Send it",
                    "color": "#FFFFFF",
                    "backgroundColor": "#EB0083",
                ],
                "image": [
                    "url": "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg",
                    "name": "image.jpeg"
                ]
        ])!,
//             image: UIImage(named: "background"),
             onDismiss: { print("Dismissed") },
             onInAppMessageClicked: { print("Button tapped") }
        )
    }
}
