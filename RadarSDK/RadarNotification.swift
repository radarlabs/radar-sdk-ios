//
//  RadarNotification.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

let RADAR_NOTIFICATION_PREFIX = "radar_"
let GEOFENCE_NOTIFICATION_PREFIX = "radar_geofence_"

struct RadarNotificationContent: Sendable, Hashable {
    let campaignId: String
    let notificationText: String
    let notificationTitle: String?
    let notificationSubtitle: String?
    let notificationURL: String?
    let campaignMetadata: String?

    init?(from metadata: [String: RadarMetadataValue]) {
        // required fields
        guard let notificationText = metadata["radar:notificationText"]?.string(),
            let campaignId = metadata["radar:campaignId"]?.string()
        else {
            return nil
        }
        self.notificationText = notificationText
        self.campaignId = campaignId

        // optional fields
        self.notificationTitle = metadata["radar:notificationTitle"]?.string()
        self.notificationSubtitle = metadata["radar:notificationSubtitle"]?.string()
        self.notificationURL = metadata["radar:notificationURL"]?.string()
        self.campaignMetadata = metadata["radar:campaignMetadata"]?.string()
    }

    func toNotificationContent(userInfo: [String: Any]) -> UNNotificationContent {
        let content = UNMutableNotificationContent()

        if let notificationTitle {
            content.title = NSString.localizedUserNotificationString(forKey: notificationTitle, arguments: nil)
        }
        if let notificationSubtitle {
            content.subtitle = NSString.localizedUserNotificationString(forKey: notificationSubtitle, arguments: nil)
        }
        content.body = NSString.localizedUserNotificationString(forKey: notificationText, arguments: nil)

        content.userInfo = userInfo
        content.userInfo["campaignId"] = campaignId
        content.userInfo["url"] = notificationURL
        if let data = campaignMetadata?.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data)
        {
            content.userInfo["campaignMetadata"] = json
        }

        return content
    }
}

extension RadarGeofenceSwift {
    private static let schedulingWindowFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter
    }()
    // "yyyy-MM-dd'T'HH:mm:ss.SSS" is 23 chars; prefix to this length strips any trailing timezone suffix so the string is parsed as wall-clock local time
    private static let schedulingWindowDatePrefixLength = 23

    func toNotificationRequest(now: Date = Date()) -> UNNotificationRequest? {
        if !isWithinSchedulingWindow(now: now) {
            return nil
        }

        if !isActiveOnDayOfWeek(now: now) {
            RadarLogger.debug("CSGN skip \(id): not active on today's day of week")
            return nil
        }

        let identifier = GEOFENCE_NOTIFICATION_PREFIX + id
        // Content
        guard let metadata = metadata,
            let metadataContent = RadarNotificationContent(from: metadata)
        else {
            return nil
        }

        if case .bool(true)? = metadata["radar:restrictToOperatingHours"] {
            let closeBufferMinutes: Int = {
                if case let .int(value)? = metadata["radar:operatingHoursCloseBufferMinutes"] {
                    return max(0, value)
                }
                return 0
            }()
            if !RadarOperatingHoursEvaluator.isOpen(
                operatingHours: operatingHours,
                now: now,
                closeBufferMinutes: closeBufferMinutes
            ) {
                return nil
            }
        }

        guard let geofenceData = try? JSONEncoder().encode(self) else {
            return nil
        }
        var userInfo: [String: Any] = [
            "registeredAt": now.timeIntervalSince1970,
            "identifier": identifier,
            "geofenceId": id,
            "geofenceData": geofenceData,
        ]

        // Forward only Radar-namespaced metadata onto the notification (and thus the tap
        // conversion). Avoids leaking arbitrary/custom geofence metadata into /events while
        // preserving all campaign fields.
        for (key, value) in metadata where key.hasPrefix("radar:") {
            userInfo[key] = value.anyValue
        }
        let content = metadataContent.toNotificationContent(userInfo: userInfo)

        // Trigger
        let latitude = geometry.center.latitude
        let longitude = geometry.center.longitude
        let radius = geometry.radius
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        let repeats = if case let .bool(value)? = metadata["radar:notificationRepeats"] { value } else { false }
        let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func isWithinSchedulingWindow(now: Date) -> Bool {
        let formatter = RadarGeofenceSwift.schedulingWindowFormatter
        let prefixLength = RadarGeofenceSwift.schedulingWindowDatePrefixLength
        // Window is [startsAt, endsAt]: skip when now is before the window opens
        if let startsAtStr = metadata?["radar:startsAt"]?.string() {
            let datePart = String(startsAtStr.prefix(prefixLength))
            if let startsAt = formatter.date(from: datePart), now < startsAt {
                return false
            }
        }
        // Window is [startsAt, endsAt]: skip when now is strictly past the end (end is inclusive)
        if let endsAtStr = metadata?["radar:endsAt"]?.string() {
            let datePart = String(endsAtStr.prefix(prefixLength))
            if let endsAt = formatter.date(from: datePart), now > endsAt {
                return false
            }
        }
        return true
    }

    private func isActiveOnDayOfWeek(now: Date) -> Bool {
        // `radar:daysOfWeek` is a comma-separated list of day abbreviations ("Sun"…"Sat"); the
        // campaign only fires on the listed days. An absent or empty value means every day.
        guard let daysOfWeekStr = metadata?["radar:daysOfWeek"]?.string() else {
            return true
        }
        let allowedDays = Set(
            daysOfWeekStr
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }
        )
        if allowedDays.isEmpty {
            return true
        }
        guard let today = RadarOperatingHoursEvaluator.weekdayAbbreviation(for: now)?.lowercased() else {
            return true
        }
        return allowedDays.contains(today)
    }
}

struct NotificationValue: Codable, Hashable {
    let identifier: String
    let registeredAt: Double
    let geofenceId: String?
    let campaignId: String?

    init?(from request: UNNotificationRequest) {
        if !request.identifier.starts(with: RADAR_NOTIFICATION_PREFIX) {
            return nil
        }
        let userInfo = request.content.userInfo
        guard let registeredAt = userInfo["registeredAt"] as? Double else {
            return nil
        }

        self.identifier = request.identifier
        self.registeredAt = registeredAt

        self.geofenceId = userInfo["geofenceId"] as? String
        self.campaignId = userInfo["campaignId"] as? String
    }
}

struct NotificationPermissions: Codable {

    enum AuthorizedStatus: String, Codable {
        case denied = "denied"
        case authorized = "authorized"
        case notDetermined = "not_determined"
        case ephemeral = "ephemeral"
        case provisional = "provisional"
        case unknown = "unknown"
    }

    let alert: Bool?
    let sound: Bool?
    let badge: Bool?
    let lockScreen: Bool?
    let notificationCenter: Bool?
    let authorizationStatus: AuthorizedStatus

    func canSendNotification() -> Bool {
        // whether or not any notifications will be sent, when all notification types are disabled, iOS will not return anything from pending notifications list
        // if that is the case, mostly likely the user has not received any notifications in the pending list.
        return authorizationStatus == .authorized && (alert == true || sound == true || badge == true || lockScreen == true || notificationCenter == true)
    }
}

extension NotificationPermissions {
    init(from settings: UNNotificationSettings) {
        switch settings.alertSetting {
        case .notSupported:
            alert = nil
        case .disabled:
            alert = false
        case .enabled:
            alert = true
        @unknown default:
            alert = nil
        }
        switch settings.badgeSetting {
        case .notSupported:
            badge = nil
        case .disabled:
            badge = false
        case .enabled:
            badge = true
        @unknown default:
            badge = nil
        }
        switch settings.lockScreenSetting {
        case .notSupported:
            lockScreen = nil
        case .disabled:
            lockScreen = false
        case .enabled:
            lockScreen = true
        @unknown default:
            lockScreen = nil
        }
        switch settings.soundSetting {
        case .notSupported:
            sound = nil
        case .disabled:
            sound = false
        case .enabled:
            sound = true
        @unknown default:
            sound = nil
        }
        switch settings.notificationCenterSetting {
        case .notSupported:
            notificationCenter = nil
        case .disabled:
            notificationCenter = false
        case .enabled:
            notificationCenter = true
        @unknown default:
            notificationCenter = nil
        }
        switch settings.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .denied:
            authorizationStatus = .denied
        case .authorized:
            authorizationStatus = .authorized
        case .provisional:
            authorizationStatus = .provisional
        case .ephemeral:
            authorizationStatus = .ephemeral
        @unknown default:
            authorizationStatus = .unknown
        }
    }
}
