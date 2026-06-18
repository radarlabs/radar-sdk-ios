//
//  OverlayPickerSheet.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Modal sheet listing every registered map source as a Toggle row.
/// Presented from the map's layer-toggle floating button.
struct OverlayPickerSheet: View {
    @EnvironmentObject var registry: MapOverlayRegistry
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Layers"), footer: footer) {
                    ForEach(registry.sources, id: \.id) { source in
                        Toggle(
                            isOn: Binding(
                                get: { registry.isEnabled(source) },
                                set: { _ in registry.toggle(source) }
                            )
                        ) {
                            Label(source.name, systemImage: source.icon)
                        }
                    }
                }
            }
            .navigationTitle("Map Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var footer: some View {
        Text("Toggle individual data sources. Layer state is persisted across launches.")
            .font(.footnote)
            .foregroundColor(.secondary)
    }
}
