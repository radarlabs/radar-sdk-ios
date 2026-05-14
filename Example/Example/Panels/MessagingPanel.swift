//
//  MessagingPanel.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

struct MessagingPanel: View {
    @EnvironmentObject var logStream: LogStream

    var body: some View {
        TogglePanel("IAM & Conversions", initiallyExpanded: false) {
            ActionButton("iam") {
                Radar.showInAppMessage(
                    RadarInAppMessage.fromDictionary([
                        "title": [
                            "text": "This is the title",
                            "color": "#ff0000",
                        ],
                        "body": [
                            "text": "This is a demo message.",
                            "color": "#00ff00",
                        ],
                        "button": [
                            "text": "Buy it",
                            "color": "#0000ff",
                            "backgroundColor": "#EB0083",
                        ],
                        "image": [
                            "url": "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg",
                            "name": "image.jpeg",
                        ],
                        "metadata": [
                            "campainId": "1234"
                        ],
                    ])!)
            }
            ActionButton("logConversion") {
                Radar.logConversion(name: "conversion_event", metadata: ["data": "test"]) { (status, event) in
                    let conversionName = (event?.type == .conversion) ? event?.conversionName : nil
                    let detail = """
                        conversionName: \(conversionName ?? "—")
                        event: \(String(describing: event))
                        """
                    logStream.write(
                        status,
                        summary: "logConversion: \(Radar.stringForStatus(status))",
                        detail: detail
                    )
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        MessagingPanel().padding()
    }
    .environmentObject(LogStream())
}
