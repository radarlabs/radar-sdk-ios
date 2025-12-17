import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes

struct TripActivityExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var name: String
        var tripId: String
        var status: String
        var etaDuration: Double?
        var mode: String?
        var destinationAddress: String?
    }
}

// MARK: - Main Widget

@available(iOS 16.2, *)
struct TripActivityExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityExtensionAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RadarArrowImage(variant: .white, size: 30)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding(.leading, 16)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(TripFormatters.formatDuration(context.state.etaDuration, compact: true))
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 16)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center, spacing: 4) {
                        ProgressBar(
                            currentStep: TripFormatters.mapStatusToStep(context.state.status),
                            isDynamicIsland: true
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            } compactLeading: {
                ModeImageView(mode: context.state.mode, width: 18, height: 18, topPadding: 0)
            } compactTrailing: {
                Text(TripFormatters.formatDuration(context.state.etaDuration, compact: true))
                    .foregroundColor(.white)
            } minimal: {
                ModeImageView(mode: context.state.mode, width: 18, height: 18, topPadding: 0)
            }
        }
    }
}

// MARK: - Preview Data

@available(iOS 16.2, *)
extension TripActivityExtensionAttributes {
    fileprivate static var preview: TripActivityExtensionAttributes {
        TripActivityExtensionAttributes()
    }
}

@available(iOS 16.2, *)
extension TripActivityExtensionAttributes.ContentState {
    fileprivate static var started: TripActivityExtensionAttributes.ContentState {
        TripActivityExtensionAttributes.ContentState(
            name: "My Trip",
            tripId: "trip_123",
            status: "started",
            etaDuration: 15.5,
            mode: "car",
            destinationAddress: "123 Main St, San Francisco, CA"
        )
    }
    
    fileprivate static var approaching: TripActivityExtensionAttributes.ContentState {
        TripActivityExtensionAttributes.ContentState(
            name: "My Trip",
            tripId: "trip_123",
            status: "approaching",
            etaDuration: 2.0,
            mode: "car",
            destinationAddress: "123 Main St, San Francisco, CA"
        )
    }
}

@available(iOS 18.0, *)
#Preview("Notification", as: .content, using: TripActivityExtensionAttributes.preview) {
    TripActivityExtensionLiveActivity()
} contentStates: {
    TripActivityExtensionAttributes.ContentState.started
    TripActivityExtensionAttributes.ContentState.approaching
}
