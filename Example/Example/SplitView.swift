//
//  SplitView.swift
//  Example
//
//  Created by ShiCheng Lu on 11/21/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

struct SplitView<PrimaryView: View, SecondaryView: View>: View {

    // MARK: Props

    @GestureState private var offset: CGFloat = 0
    @State private var storedOffset: CGFloat = 0

    let top: PrimaryView
    let bot: SecondaryView


    // MARK: Initilization

    init(
        @ViewBuilder top: @escaping () -> PrimaryView,
        @ViewBuilder bottom: @escaping () -> SecondaryView)
    {
        self.top = top()
        self.bot = bottom()
    }


    // MARK: Body

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                self.top
                    .frame(height: (proxy.size.height / 2) + self.totalOffset)

                self.handle
                    .gesture(
                        DragGesture()
                            .updating(self.$offset, body: { value, state, _ in
                                state = value.translation.height
                            })
                            .onEnded { value in
                                self.storedOffset += value.translation.height
                            }
                    )
                    .offset(y: -self.offset)

                self.bot
            }
        }
    }


    // MARK: Computed Props

    var handle: some View {
        RoundedRectangle(cornerRadius: 5)
            .frame(width: 40, height: 3)
            .foregroundColor(Color.gray)
            .padding(2)
    }

    var totalOffset: CGFloat {
        storedOffset + offset
    }
}

#Preview {
    SplitView {
        Text("yes")
    } bottom: {
        Text("no")
    }

}
