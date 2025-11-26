//
//  SettingsView.swift
//  Example
//
//  Created by ShiCheng Lu on 11/21/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("radar-prediction-average-window") var predictionAverageWindow: Int = 1
    @AppStorage("radar-measurement-drop-filter") var measurementDropFilter: Int = 0
    @AppStorage("radar-calibration-mode") var calibrationMode: Bool = false
    @AppStorage("radar-kalman-filter") var kalmanFilter: Bool = true
    @AppStorage("radar-raw-prediction") var rawPrediction: Bool = false
    @AppStorage("radar-prediction-confidence") var predictionConfidence: Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            Stepper {
                Text("Average window: \(predictionAverageWindow)")
            } onIncrement: {
                predictionAverageWindow += 1
            } onDecrement: {
                predictionAverageWindow = max(1, predictionAverageWindow - 1)
            }
            
            Stepper {
                Text("Measurement drop filter: \(measurementDropFilter)")
            } onIncrement: {
                measurementDropFilter += 1
            } onDecrement: {
                measurementDropFilter = max(0, measurementDropFilter - 1)
            }
            
            Toggle(isOn: $calibrationMode) {
                Text("Calibration mode")
            }
            
            Toggle(isOn: $kalmanFilter) {
                Text("Kalman filter")
            }
            
            Toggle(isOn: $rawPrediction) {
                Text("Raw prediction")
            }
            
            Toggle(isOn: $predictionConfidence) {
                Text("Prediction confidence")
            }
        }
    }
}

#Preview {
    DebugView()
}
