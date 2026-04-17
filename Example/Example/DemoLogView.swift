//
//  DemoLogView.swift
//  Example
//
//  Created by Alan Charles on 4/17/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
struct DemoLogView: View {
    @State private var entries: [String] = []
    private let refreshTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    var body: some View {
        NavigationView {
            List(entries.reversed(), id: \.self) {
                Text($0).font(.system(.caption, design: .monospaced))
            }
            .navigationTitle("Offline log")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { DemoLog.clear(); entries = [] }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Copy") { UIPasteboard.general.string = entries.joined(separator: "\n") }
                }
            }
            .onAppear { entries = DemoLog.read() }
            .onReceive(refreshTimer) { _ in entries = DemoLog.read() }
        }
    }
}
