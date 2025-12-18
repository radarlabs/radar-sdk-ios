//
//  TestsView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import CoreLocation
import RadarSDK

struct TestsView: View {
    @State private var userId: String = "test-driver-\(Int.random(in: 1000...9999))"
    @State private var tripExternalId: String = "multi-leg-trip-\(Int.random(in: 1000...9999))"
    @State private var statusMessage: String = "Ready"
    @State private var tripInfo: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - User ID Section
                GroupBox(label: Text("User Setup").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("User ID", text: $userId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        StyledButton("Set User ID") {
                            Radar.setUserId(userId)
                            statusMessage = "✅ User ID set to: \(userId)"
                        }
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Trip External ID
                GroupBox(label: Text("Trip Setup").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Trip External ID", text: $tripExternalId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Status Display
                GroupBox(label: Text("Status").font(.headline)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusMessage)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        if !tripInfo.isEmpty {
                            Divider()
                            Text(tripInfo)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // MARK: - Multi-Leg Trip Actions
                GroupBox(label: Text("Multi-Leg Trip").font(.headline)) {
                    VStack(spacing: 12) {
                        StyledButton("🚀 Start Multi-Leg Trip") {
                            startMultiLegTrip()
                        }
                        
                        StyledButton("📍 View Current Trip State") {
                            viewTripState()
                        }
                        
                        StyledButton("✅ Complete Current Leg") {
                            completeCurrentLeg()
                        }
                        
                        StyledButton("🏁 Complete Entire Trip") {
                            Radar.completeTrip { status, trip, events in
                                if status == .success {
                                    statusMessage = "✅ Trip completed!"
                                    tripInfo = ""
                                } else {
                                    statusMessage = "❌ Failed to complete trip: \(Radar.stringForStatus(status))"
                                }
                            }
                        }
                        
                        StyledButton("❌ Cancel Trip") {
                            Radar.cancelTrip { status, trip, events in
                                if status == .success {
                                    statusMessage = "🚫 Trip cancelled"
                                    tripInfo = ""
                                } else {
                                    statusMessage = "❌ Failed to cancel trip: \(Radar.stringForStatus(status))"
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Tracking Actions
                GroupBox(label: Text("Tracking").font(.headline)) {
                    VStack(spacing: 12) {
                        StyledButton("📡 Track Once") {
                            Radar.trackOnce { status, location, events, user in
                                statusMessage = "Track: \(Radar.stringForStatus(status))"
                                if let loc = location {
                                    statusMessage += "\n📍 \(loc.coordinate.latitude), \(loc.coordinate.longitude)"
                                }
                            }
                        }
                        
                        StyledButton("🗺️ Mock Tracking (3 steps)") {
                            let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
                            let destination = CLLocation(latitude: 40.73851, longitude: -73.98788) // Near Gramercy Park
                            
                            Radar.mockTracking(
                                origin: origin,
                                destination: destination,
                                mode: .car,
                                steps: 3,
                                interval: 3
                            ) { status, location, events, user in
                                statusMessage = "Mock track: \(Radar.stringForStatus(status))"
                                if let events = events, !events.isEmpty {
                                    statusMessage += "\n📬 \(events.count) event(s)"
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Multi-Leg Trip Functions
    
    private func startMultiLegTrip() {
        statusMessage = "Starting multi-leg trip..."
        
        // Leg 1: Address destination
        let leg1 = RadarTripLeg(address: "32 Gramercy Park South, New York, NY 10003")
        leg1.metadata = ["stopNumber": "1", "type": "delivery"]
        leg1.stopDuration = 5
        
        // Leg 2: Geofence destination (Union Square)
        let leg2 = RadarTripLeg(destinationGeofenceTag: "nyc", destinationGeofenceExternalId: "usq")
        leg2.metadata = ["stopNumber": "2", "type": "pickup"]
        leg2.stopDuration = 3
        
        // Leg 3: Geofence destination (HQ - final destination)
        let leg3 = RadarTripLeg(destinationGeofenceTag: "nyc", destinationGeofenceExternalId: "hq")
        leg3.metadata = ["stopNumber": "3", "type": "return-to-base"]
        
        // Create trip options with all legs
        let tripOptions = RadarTripOptions(
            externalId: tripExternalId,
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil
        )
        tripOptions.mode = .car
        tripOptions.legs = [leg1, leg2, leg3]
        
        // Start the trip
        Radar.startTrip(options: tripOptions) { status, trip, events in
            if status == .success {
                statusMessage = "✅ Multi-leg trip started!"
                if let trip = trip {
                    updateTripInfo(trip)
                }
            } else {
                statusMessage = "❌ Failed to start trip: \(Radar.stringForStatus(status))"
            }
        }
    }
    
    private func viewTripState() {
        guard let trip = Radar.getTrip() else {
            statusMessage = "ℹ️ No active trip"
            tripInfo = ""
            return
        }
        
        statusMessage = "📋 Current trip state:"
        updateTripInfo(trip)
    }
    
    private func completeCurrentLeg() {
        guard Radar.getTrip() != nil else {
            statusMessage = "❌ No active trip found"
            return
        }
        
        statusMessage = "Completing current leg..."
        
        // Use the new convenience function - no need to manually get tripId or legId!
        Radar.updateCurrentTripLeg(status: .completed) { status, updatedTrip, updatedLeg, events in
            if status == .success {
                // Check if this completed the entire trip
                if let trip = updatedTrip, trip.status == .completed {
                    statusMessage = "🎉 Final leg completed - Trip finished!"
                    tripInfo = "Trip completed at \(Date())"
                } else {
                    statusMessage = "✅ Leg completed!"
                    if let updatedTrip = updatedTrip {
                        updateTripInfo(updatedTrip)
                    }
                }
                
                if let events = events, !events.isEmpty {
                    let eventTypes = events.map { Radar.stringForEventType($0.type) }.joined(separator: ", ")
                    statusMessage += "\n📬 Events: \(eventTypes)"
                }
            } else {
                statusMessage = "❌ Failed to complete leg: \(Radar.stringForStatus(status))"
            }
        }
    }
    
    private func updateTripInfo(_ trip: RadarTrip) {
        var info = """
        Trip: \(trip.externalId ?? trip._id)
        Status: \(Radar.stringForTripStatus(trip.status))
        Current Leg: \(trip.currentLegId ?? "none")
        """
        
        // Show trip-level ETA (to final destination)
        if trip.etaDuration > 0 || trip.etaDistance > 0 {
            info += "\n🏁 Final ETA: \(formatEta(duration: trip.etaDuration, distance: trip.etaDistance))"
        }
        
        info += "\n"
        
        if let legs = trip.legs {
            info += "\nLegs (\(legs.count)):\n"
            for (index, leg) in legs.enumerated() {
                let statusEmoji: String
                switch leg.status {
                case .completed: statusEmoji = "✅"
                case .started: statusEmoji = "🚗"
                case .approaching: statusEmoji = "📍"
                case .arrived: statusEmoji = "🏁"
                case .pending: statusEmoji = "⏳"
                case .canceled: statusEmoji = "❌"
                case .expired: statusEmoji = "⏰"
                default: statusEmoji = "❓"
                }
                
                let destination: String
                if let tag = leg.destinationGeofenceTag, let extId = leg.destinationGeofenceExternalId {
                    destination = "\(tag)/\(extId)"
                } else if let address = leg.address {
                    destination = String(address.prefix(25)) + "..."
                } else if leg.hasCoordinates {
                    destination = "(\(String(format: "%.4f", leg.coordinates.latitude)), \(String(format: "%.4f", leg.coordinates.longitude)))"
                } else {
                    destination = "unknown"
                }
                
                let isCurrent = leg._id == trip.currentLegId ? " 👈" : ""
                info += "  \(index + 1). \(statusEmoji) \(destination)\(isCurrent)\n"
                
                // Show leg ETA if available
                if leg.etaDuration > 0 || leg.etaDistance > 0 {
                    info += "      ⏱️ \(formatEta(duration: leg.etaDuration, distance: leg.etaDistance))\n"
                }
            }
        }
        
        tripInfo = info
    }
    
    private func formatEta(duration: Float, distance: Float) -> String {
        var parts: [String] = []
        
        if duration > 0 {
            if duration >= 60 {
                let hours = Int(duration) / 60
                let mins = Int(duration) % 60
                parts.append("\(hours)h \(mins)m")
            } else {
                parts.append("\(Int(duration)) min")
            }
        }
        
        if distance > 0 {
            if distance >= 1000 {
                let km = distance / 1000
                parts.append(String(format: "%.1f km", km))
            } else {
                parts.append("\(Int(distance)) m")
            }
        }
        
        return parts.isEmpty ? "N/A" : parts.joined(separator: " / ")
    }
}

#Preview {
    TestsView()
}
