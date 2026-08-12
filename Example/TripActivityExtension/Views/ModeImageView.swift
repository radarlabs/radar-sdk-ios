//
//  ModeImageView.swift
//  Example
//
//  Created by Alan Charles on 12/9/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import WidgetKit
import SwiftUI

struct ModeImageView: View {
    let mode: String?
    let width: CGFloat
    let height: CGFloat
    let topPadding: CGFloat
    
    init(mode: String?, width: CGFloat = 30, height: CGFloat = 30, topPadding: CGFloat = 4) {
        self.mode = mode
        self.width = width
        self.height = height
        self.topPadding = topPadding
    }
    
    var body: some View {
        Image(imageName(for: mode))
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
            .padding(.top, topPadding)
            .foregroundColor(.white)
    }
    
    private func imageName(for mode: String?) -> String {
        switch mode {
        case "car":
            return "radarCarWhite"
        case "bike":
            return "radarBikeWhite"
        default:
            return "radarWalkingWhite"
        }
    }
}
