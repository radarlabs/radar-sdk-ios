//
//  RadarArrowImage.swift
//  Example
//
//  Created by Alan Charles on 12/9/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.2, *)
struct RadarArrowImage: View {
    enum Variant {
        case twilight, white
        
        var imageName: String {
            switch self {
            case .twilight: return "RadarArrowTwilight"
            case .white: return "RadarArrowWhite"
            }
        }
    }
    
    let variant: Variant
    var size: CGFloat = 20
    
    var body: some View {
        Image(variant.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
