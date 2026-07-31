//
//  AR.swift
//  Example
//
//  Created by ShiCheng Lu on 11/3/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import ARKit
import SwiftUI

// MARK: - UIViewRepresentable for ARSCNView (or ARView)
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: SurveyViewModel

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = viewModel.session
        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        // Start the camera/world-tracking session only now that the AR view is on screen.
        viewModel.startSession()
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Nothing to update for now
    }

    // Pause the session when the AR view leaves the hierarchy (e.g. calibration mode is
    // switched off) so the camera stops running.
    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        var container: ARViewContainer
        init(_ container: ARViewContainer) {
            self.container = container
        }
        // You can implement delegate methods if you want (e.g., for debug)
    }
}
