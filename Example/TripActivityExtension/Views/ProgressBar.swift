//
//  ProgressBar.swift
//  Example
//
//  Created by Alan Charles on 12/1/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int = 4
    var isDynamicIsland: Bool = false
    
    var progressColor: Color {
        isDynamicIsland ? .white : TripColors.twilight
    } 

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? progressColor : Color(UIColor(hexString: "#ACBDC8")).opacity(0.5))
                    .frame(width: step == currentStep ? 30 : 12, height: step == currentStep ? 30 : 12)
                    .overlay(
                        Group {
                            if step == currentStep {
                                Image(iconForStep(step))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                            }
                        }
                    )

                if step < totalSteps {
                    if #available(iOS 15.0, *) {
                        Rectangle()
                            .fill(rectangleFill(for: step))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    } else {
                        Rectangle()
                            .fill(Color(UIColor(hexString: "#ACBDC8")).opacity(0.5))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    func iconForStep(_ step: Int) -> String {
        let baseIcon: String
        switch step {
        case 1:
            baseIcon = "radarFlagStart"
        case 2:
            baseIcon = "radarWalking"
        case 3:
            baseIcon = "radarWalking"
        case 4:
            baseIcon = "radarFlagEnd"
        default:
            baseIcon = "radarFlagStar"
        }
        if isDynamicIsland == true {
             return baseIcon + "Blue"
        } else {
            return baseIcon + "White"
        }
    }
    
    @available(iOS 15.0, *)
    func rectangleFill(for step: Int) -> AnyShapeStyle {
        let incompleteStepColor = Color(UIColor(hexString: "#ACBDC8")).opacity(0.5)
        if step > currentStep - 1 {
            return AnyShapeStyle(incompleteStepColor)
        } else {
            return AnyShapeStyle(progressColor)
        }
    }
}

