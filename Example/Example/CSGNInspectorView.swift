//
//  CSGNInspectorView.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import RadarSDK
import SwiftUI
import UserNotifications

/// General-purpose inspector for client-side geofence notifications (CSGNs).
///
/// Snapshots the live registered state using public APIs only — no campaign-specific
/// hardcoding — so it works for any CSGN. It surfaces what the pending-notification list
/// alone can't: each region's geometry, whether the device is currently inside a region
/// (iOS won't fire an entry trigger until you leave and re-enter), and the location /
/// notification authorization that gate background delivery.
///
/// Pair this with `Radar.setLogLevel(.debug)` + the Debug tab: this view shows what *is*
/// registered and whether it can fire; the SDK's `CSGN skip <id>: ...` logs explain why a
/// geofence was *not* registered.
struct CSGNInspectorView: View {

    /// `radar_geofence_` notifications are the client-side geofence triggers registered by
    /// the SDK. The prefix is internal to RadarSDK, so it is duplicated here intentionally.
    private static let radarGeofencePrefix = "radar_geofence_"

    private struct CSGNRow: Identifiable {
        let id: String
        let title: String
        let body: String
        let campaignId: String
        let campaignType: String
        let daysOfWeek: String
        let startsAt: String
        let endsAt: String
        let restrictToOperatingHours: String
        let repeats: String
        let center: CLLocationCoordinate2D?
        let radius: Double?
        let isInside: Bool?          // nil = no current location to compare against
        let distanceToCenter: Double?
    }

    @State private var locationAuth = "—"
    @State private var notificationAuth = "—"
    @State private var currentLocationText = "—"
    @State private var rows: [CSGNRow] = []
    @State private var lastRefreshed = "never"
    @State private var showFiringSteps = true

    /// Recommended distance to walk past the edge before re-entering, derived from the
    /// largest registered region. GPS error is added to the radius, so we suggest the
    /// greater of 2× the radius or radius + 150 m (≥200 m when nothing is registered yet).
    private var recommendedOutMeters: Int {
        guard let maxRadius = rows.compactMap(\.radius).max() else { return 200 }
        return Int(max(maxRadius * 2, maxRadius + 150).rounded())
    }

    private var firingSteps: [String] {
        [
            "1. Use a large, isolated geofence (≥150–200 m radius). Make it big enough to walk through the center, not just clip the edge — small (<100 m) or overlapping geofences fire inconsistently.",
            "2. Pick a spot you can reach from well outside, and don't place it where you're already standing (a region you start INSIDE won't fire).",
            "3. Set Location permission to Always (Settings → this app → Location). Background entries aren't delivered with \"While Using\".",
            "4. Start OUTSIDE the geofence. Any region marked INSIDE below won't fire until you leave first.",
            "5. Walk/drive at least ~\(recommendedOutMeters) m past the edge, then stay out ~1–2 min so iOS registers the exit and the SDK re-registers the region while you're outside.",
            "6. Head back in through the center, and keep moving — iOS detects crossings from motion + cell/Wi-Fi, not constant GPS.",
            "7. Delivery takes ~20 s to a few minutes. In the foreground, watch for the banner / the \"will present notification!\" console log.",
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DisclosureGroup(isExpanded: $showFiringSteps) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(firingSteps.enumerated()), id: \.offset) { _, step in
                            Text(step)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                } label: {
                    Text("How to make a CSGN fire").bold()
                }
                .font(.system(.footnote, design: .monospaced))
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(8)

                Group {
                    Text("Location auth: \(locationAuth)")
                    Text("Notification auth: \(notificationAuth)")
                    Text("Current location: \(currentLocationText)")
                    Text("Registered CSGNs: \(rows.count)  (~20 region/app budget, shared with tracking)")
                    Text("Refreshed: \(lastRefreshed)")
                }
                .font(.system(.footnote, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                if rows.isEmpty {
                    Text("No radar_geofence_* notifications pending. If a campaign should be here, check the Debug tab for `CSGN skip` logs.")
                        .font(.system(.footnote, design: .monospaced))
                }

                ForEach(rows) { row in
                    rowView(row)
                }
            }
            .padding()
        }
        .onAppear { refresh() }
    }

    @ViewBuilder
    private func rowView(_ row: CSGNRow) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.title.isEmpty ? row.id : row.title).bold()
            Text("body: \(row.body)")
            Text("geofenceId: \(row.id)")
            Text("campaignId: \(row.campaignId)  type: \(row.campaignType)")
            Text("daysOfWeek: \(row.daysOfWeek)")
            Text("startsAt: \(row.startsAt)")
            Text("endsAt: \(row.endsAt)")
            Text("restrictToOperatingHours: \(row.restrictToOperatingHours)  repeats: \(row.repeats)")

            if let center = row.center, let radius = row.radius {
                Text(String(format: "region: (%.6f, %.6f) r=%.0fm", center.latitude, center.longitude, radius))
                switch row.isInside {
                case .some(true):
                    Text("⚠️ INSIDE this region — iOS won't fire entry until you exit & re-enter")
                        .foregroundColor(.red)
                case .some(false):
                    if let d = row.distanceToCenter {
                        Text(String(format: "OUTSIDE — %.0fm to center, %.0fm to edge", d, d - radius))
                            .foregroundColor(.green)
                    }
                case .none:
                    Text("location unknown — can't determine inside/outside")
                }
            } else {
                Text("no location trigger / region")
            }
        }
        .font(.system(.caption, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func refresh() {
        locationAuth = Self.describe(CLLocationManager().authorizationStatus)

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let auth = Self.describe(settings.authorizationStatus)
            DispatchQueue.main.async { notificationAuth = auth }
        }

        // Fetch a fresh location first, then build the rows relative to it so each region's
        // inside/outside + distance is accurate.
        Radar.getLocation { _, location, _ in
            DispatchQueue.main.async {
                if let location = location {
                    currentLocationText = String(
                        format: "(%.6f, %.6f) ±%.0fm",
                        location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy
                    )
                } else {
                    currentLocationText = "unavailable"
                }
                buildRows(current: location)
            }
        }
    }

    private func buildRows(current: CLLocation?) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let built: [CSGNRow] = requests
                .filter { $0.identifier.hasPrefix(Self.radarGeofencePrefix) }
                .map { request in
                    let userInfo = request.content.userInfo
                    let region = (request.trigger as? UNLocationNotificationTrigger)?.region as? CLCircularRegion

                    var isInside: Bool?
                    var distance: Double?
                    if let region = region, let current = current {
                        isInside = region.contains(current.coordinate)
                        distance = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
                            .distance(from: current)
                    }

                    return CSGNRow(
                        id: (userInfo["geofenceId"] as? String) ?? request.identifier,
                        title: request.content.title,
                        body: request.content.body,
                        campaignId: Self.str(userInfo["radar:campaignId"]),
                        campaignType: Self.str(userInfo["radar:campaignType"]),
                        daysOfWeek: Self.str(userInfo["radar:daysOfWeek"]),
                        startsAt: Self.str(userInfo["radar:startsAt"]),
                        endsAt: Self.str(userInfo["radar:endsAt"]),
                        restrictToOperatingHours: Self.str(userInfo["radar:restrictToOperatingHours"]),
                        repeats: Self.str(userInfo["radar:notificationRepeats"]),
                        center: region?.center,
                        radius: region?.radius,
                        isInside: isInside,
                        distanceToCenter: distance
                    )
                }
            DispatchQueue.main.async {
                rows = built
                lastRefreshed = Self.timeString()
            }
        }
    }

    private static func str(_ value: Any?) -> String {
        guard let value = value else { return "—" }
        return "\(value)"
    }

    private static func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "WhenInUse ⚠️ (background CSGNs need Always)"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "NotDetermined"
        @unknown default: return "Unknown"
        }
    }

    private static func describe(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        case .denied: return "Denied"
        case .notDetermined: return "NotDetermined"
        @unknown default: return "Unknown"
        }
    }

    private static func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

#Preview {
    CSGNInspectorView()
}
