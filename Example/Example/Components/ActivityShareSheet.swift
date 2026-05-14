//
//  ActivityShareSheet.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// SwiftUI bridge for `UIActivityViewController`. Used by `LogsView` to share
/// formatted console output via the system share sheet. `ShareLink` would be
/// simpler but is iOS 16+ only.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
