//
//  PermissionsSectionView.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import CoreMotion
import SwiftUI
import UserNotifications

/// Location / notifications / motion permission states with inline request
/// actions and a pending-Radar-notifications counter.
struct PermissionsSectionView: View {
    @ObservedObject var permissionsStore: PermissionsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            locationRow
            notificationsRow
            pendingNotificationsRow
            motionRow
        }
    }

    // MARK: - Subsections

    private var header: some View {
        HStack {
            Text("Permissions").font(.headline)
            Spacer()
            Button("Refresh") {
                permissionsStore.refreshNotificationStatus()
                permissionsStore.refreshMotionStatus()
                permissionsStore.refreshPendingRadarNotifications()
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
    }

    private var locationRow: some View {
        ControlRow("Location") {
            HStack(spacing: 8) {
                Text(permissionsStore.locationStatus.displayName)
                    .foregroundColor(permissionsStore.locationStatus.displayColor)
                locationActionButton
            }
        }
    }

    private var notificationsRow: some View {
        ControlRow("Notifications") {
            HStack(spacing: 8) {
                Text(permissionsStore.notificationStatus.displayName)
                    .foregroundColor(permissionsStore.notificationStatus.displayColor)
                notificationActionButton
            }
        }
    }

    private var pendingNotificationsRow: some View {
        ControlRow("Pending Radar notifications") {
            Text("\(permissionsStore.pendingRadarNotificationCount)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(permissionsStore.pendingRadarNotificationCount > 0 ? .primary : .secondary)
        }
    }

    private var motionRow: some View {
        ControlRow("Motion") {
            HStack(spacing: 8) {
                Text(permissionsStore.motionStatus.displayName)
                    .foregroundColor(permissionsStore.motionStatus.displayColor)
                motionActionButton
            }
        }
    }

    @ViewBuilder
    private var motionActionButton: some View {
        switch permissionsStore.motionStatus {
        case .notDetermined:
            Button("Request") { permissionsStore.requestMotionActivity() }
                .font(.caption).buttonStyle(.borderless)
        case .denied, .restricted:
            Button("Open Settings") { permissionsStore.openSystemSettings() }
                .font(.caption).buttonStyle(.borderless)
        case .authorized:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Action buttons

    @ViewBuilder
    private var locationActionButton: some View {
        switch permissionsStore.locationStatus {
        case .notDetermined:
            Button("Request") { permissionsStore.requestLocation() }
                .font(.caption).buttonStyle(.borderless)
        case .authorizedWhenInUse:
            Button("Request Always") { permissionsStore.requestLocation() }
                .font(.caption).buttonStyle(.borderless)
        case .denied, .restricted:
            Button("Open Settings") { permissionsStore.openSystemSettings() }
                .font(.caption).buttonStyle(.borderless)
        case .authorizedAlways:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var notificationActionButton: some View {
        switch permissionsStore.notificationStatus {
        case .notDetermined:
            Button("Request") { permissionsStore.requestNotifications() }
                .font(.caption).buttonStyle(.borderless)
        case .denied:
            Button("Open Settings") { permissionsStore.openSystemSettings() }
                .font(.caption).buttonStyle(.borderless)
        case .authorized, .provisional, .ephemeral:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
}
