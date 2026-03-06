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
    @ObservedObject var viewModel: DebugViewModel
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = viewModel.session
        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Nothing to update for now
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

// MARK: - SwiftUI View
struct ARView: View {
    @StateObject private var viewModel = DebugViewModel()
    var body: some View {
        ZStack(alignment: .topLeading) {
            ARViewContainer(viewModel: viewModel)
            
            VStack(alignment: .leading, spacing: 10) {
                
                Button("Reset") {
                    viewModel.resetTracking()
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            .padding(.top, 40)
            .padding(.leading, 20)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ARView()
    }
}
