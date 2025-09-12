//
//  StyledButton.swift
//  Example
//
//  Created by ShiCheng Lu on 9/12/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

struct StyledButton: View {
    
    var name: String
    var action: () -> Void = { }
    
    init(_ name: String, action: @escaping () -> Void = { }) {
        self.name = name
        self.action = action
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            Button(action: action) {
                Text(name)
                    .frame(width: 300, height: 25)
                    .contentShape(Rectangle())
                    .border(Color.blue, width: 1)
            }
        } else {
            // Fallback on earlier versions
            Button(name, action: action)
        }
    }
}

#Preview {
    StyledButton("Click me") {
        // do nothing
    }
}
