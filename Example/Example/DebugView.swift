//
//  DebugView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import CoreML
import RadarSDKIndoors

struct DebugView: View {
    
    var body: some View {
        VStack {
            Button("predict") {
                Task {
                    let features: [String: MLFeatureValue] = [
                        "seplen": MLFeatureValue(double: 6.5),
                        "sepwid": MLFeatureValue(double: 3.0),
                        "petlen": MLFeatureValue(double: 5.2),
                        "petwid": MLFeatureValue(double: 2.0),
                    ]
                    let provider = try MLDictionaryFeatureProvider(dictionary: features)
//                    let result = await RadarML.shared.predict(name: "Flower", features: provider)
                    print(provider)
                }
            }
            
            
            Button("start") {
                Task {
                    await RadarSDKIndoors.start()
                }
            }
            
            Button("stop") {
                Task {
                    await RadarSDKIndoors.stop()
                }
            }
        }
    }
}

#Preview {
    DebugView()
}
