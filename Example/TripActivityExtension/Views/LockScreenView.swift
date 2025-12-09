//
//  LockScreenView.swift
//  Example
//
//  Created by Alan Charles on 12/9/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI


@available(iOS 16.2, *)
struct LockScreenView: View {
    let context: ActivityViewContext<TripActivityExtensionAttributes>
    
    var body: some View {
        ZStack {
            content
            gradientOverlay
        }
        .activityBackgroundTint(TripColors.background)
        .activitySystemActionForegroundColor(.white)
    }
    
    // MARK: - Content
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Spacer()
            statusText
            Spacer()
            progressSection
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .padding(.top, 10)
    }
    
    // MARK: - Header
    
    private var headerRow: some View {
        HStack(alignment: .center, spacing: 8) {
            RadarArrowImage(variant: .twilight)
                .frame(width: 20, height: 20)
            
            Spacer()
            
            Text("\(context.state.destinationAddress ?? "undefined") | \(TripFormatters.formatDuration(context.state.etaDuration))")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(TripColors.twilight)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.trailing, 10)
    }
    
    // MARK: - Status
    private var statusText: some View {
        let step = TripFormatters.mapStatusToStep(context.state.status)
        return Text(TripFormatters.statusMessage(for: step))
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(TripColors.twilight)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.bottom, 12)
            .padding(.top, 6)
            .padding(.horizontal, 8)
    }
    
    // MARK: - Progress
    
    private var progressSection: some View {
        HStack(alignment: .center, spacing: 4) {
            ProgressBar(currentStep: TripFormatters.mapStatusToStep(context.state.status))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 10)
    }
    
    // MARK: - Gradient Overlay
    
    private var gradientOverlay: some View {
        VStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: TripColors.twilight.opacity(0.2), location: 0.0),
                    .init(color: TripColors.twilight.opacity(0.1), location: 0.5),
                    .init(color: Color.clear, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)
            
            Spacer()
        }
    }
}
