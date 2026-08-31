//
//  AppDelegate.swift
//  Example
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import ActivityKit
import Combine
import RadarSDK
import SwiftUI
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIWindowSceneDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, RadarVerifiedDelegate {

    /// Point the SDK at a dev server by setting this to its address, e.g.
    /// "http://192.168.1.10:8081" (device) or "http://localhost:8081" (simulator). Overrides
    /// the API + verified hosts on launch; leave blank to use the SDK defaults.
    static let TARGET_HOST = ""

    let locationManager = CLLocationManager()
    var window: UIWindow?  // required for UIWindowSceneDelegate

    let logStream = LogStream()
    let settingsStore = SettingsStore()
    let permissionsStore = PermissionsStore()
    let mapOverlayRegistry = MapOverlayRegistry()
    let tripBuilderStore = TripBuilderStore()
    private var cancellables = Set<AnyCancellable>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in }
        UNUserNotificationCenter.current().delegate = self

        locationManager.delegate = self
        self.requestLocationPermissions()

        // Replace with a valid test publishable key
        let radarInitializeOptions = RadarInitializeOptions()

        // Uncomment to enable automatic setup for notification conversions or deep linking
        radarInitializeOptions.autoLogNotificationConversions = true
        radarInitializeOptions.autoHandleNotificationDeepLinks = true
        radarInitializeOptions.silentPush = true
        radarInitializeOptions.trackVerifiedAutoFailover = true

        Radar.setAppGroup("group.waypoint.data")
        // Point the SDK at a dev server (see `TARGET_HOST`). Writes the API + verified hosts
        // to UserDefaults, or clears the overrides when `TARGET_HOST` is blank.
        let radarDefaults = UserDefaults(suiteName: "group.waypoint.data") ?? .standard
        if Self.TARGET_HOST.isEmpty {
            radarDefaults.removeObject(forKey: "radar-host")
            radarDefaults.removeObject(forKey: "radar-verifiedHost")
        } else {
            radarDefaults.set(Self.TARGET_HOST, forKey: "radar-host")
            radarDefaults.set(Self.TARGET_HOST, forKey: "radar-verifiedHost")
        }
        Radar.initialize(publishableKey: settingsStore.resolvedPublishableKey, options: radarInitializeOptions)
        Radar.setDelegate(logStream)
        wireLiveActivitySubscriptions()
        Radar.setVerifiedDelegate(self)
        Radar.setInAppMessageDelegate(MyIAMDelegate(logStream: logStream))
        settingsStore.loadFromSDK()
        mapOverlayRegistry.register(MonitoredRegionsSource())
        mapOverlayRegistry.register(NearbyGeofencesSource())
        mapOverlayRegistry.register(SyncedRegionSource())
        mapOverlayRegistry.register(NearbyPlacesSource())
        mapOverlayRegistry.register(TripGeofencesSource(store: tripBuilderStore))
        mapOverlayRegistry.register(TripDestinationSource())
        mapOverlayRegistry.register(TripBreadcrumbsSource(store: tripBuilderStore))
        mapOverlayRegistry.register(TripEventsSource(store: tripBuilderStore))

        tripBuilderStore.bind(logStream: logStream, registry: mapOverlayRegistry)
        tripBuilderStore.refreshActiveTrip()

        if #available(iOS 16.2, *) {
            TripLiveActivityManager.shared.logStream = logStream
        }

        if #available(iOS 15.0, *) {
            locationManager.startMonitoringLocationPushes { data, _ in
                let token = data?.map { String(format: "%02x", $0) }.joined() ?? "no token"
                self.logStream.write(result: "extension push token registered", detail: "token: \(token)")
                Radar.setLocationExtensionToken(token)
            }
        }

        return true
    }

    func application(
        _ app: UIApplication, open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle opening via standard URL
        return true
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let appDelegate = (UIApplication.shared.delegate as? AppDelegate) ?? self

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        let controller = UIHostingController(
            rootView: MainView()
                .environmentObject(appDelegate.logStream)
                .environmentObject(appDelegate.settingsStore)
                .environmentObject(appDelegate.permissionsStore)
                .environmentObject(appDelegate.mapOverlayRegistry)
                .environmentObject(appDelegate.tripBuilderStore)
        )
        controller.view.frame = UIScreen.main.bounds
        window.addSubview(controller.view)
        window.makeKeyAndVisible()
        self.window = window
    }

    func requestLocationPermissions() {
        var status: CLAuthorizationStatus = .notDetermined
        if #available(iOS 14.0, *) {
            // On iOS 14.0 and later, use the authorizationStatus instance property.
            status = self.locationManager.authorizationStatus
        } else {
            // Before iOS 14.0, use the authorizationStatus class method.
            status = CLLocationManager.authorizationStatus()
        }

        if #available(iOS 13.4, *) {
            // On iOS 13.4 and later, prompt for foreground first. If granted, prompt for background. The OS will show the background prompt in-app.
            if status == .notDetermined {
                self.locationManager.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse {
                self.locationManager.requestAlwaysAuthorization()
            }
        } else {
            // Before iOS 13.4, prompt for background first. On iOS 13, the OS will show a foreground prompt in-app. The OS will show the background prompt outside of the app later, at a time determined by the OS.
            self.locationManager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.requestLocationPermissions()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logStream.write(result: "willPresent notification")
        completionHandler([.list, .banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Uncomment for manual setup for notification conversions and URLs
        // Radar.logConversion(response: response)
        // Radar.openURLFromNotification(response.notification)
        logStream.write(result: "didReceive notification response", detail: "\(response)")
    }

    // this function is called ONLY for silent-pushes
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        logStream.write(result: "silent push received", detail: "\(userInfo)")

        return .newData
    }

    func notify(_ body: String) {
    }

    // MARK: - Live Activity (subscribes to LogStream)

    private func wireLiveActivitySubscriptions() {
        logStream.didReceiveEventsPublisher
            .sink { [weak self] events, _ in
                self?.handleEventsForLiveActivity(events)
            }
            .store(in: &cancellables)
        logStream.didUpdateLocationPublisher
            .sink { [weak self] _, user in
                self?.handleLocationUpdateForLiveActivity(user: user)
            }
            .store(in: &cancellables)
    }

    private func handleEventsForLiveActivity(_ events: [RadarEvent]) {
        if #available(iOS 16.2, *) {
            for event in events where event.type == .userStoppedTrip {
                TripLiveActivityManager.shared.endActivity(status: "completed")
            }
        }
    }

    private func handleLocationUpdateForLiveActivity(user: RadarUser) {
        if #available(iOS 16.2, *) {
            if user.trip != nil {
                handleTripLiveActivity(user: user)
            }
        }
    }

    // MARK: - Live Activity Handling
    @available(iOS 16.2, *)
    private func handleTripLiveActivity(user: RadarUser?) {
        guard let trip = user?.trip else {
            TripLiveActivityManager.shared.endActivity(status: "completed")
            return
        }

        let hasActivity = TripLiveActivityManager.shared.hasActiveActivity

        switch trip.status {
        case .started, .approaching, .arrived:
            if !hasActivity {
                TripLiveActivityManager.shared.startActivity(trip: trip)
            } else {
                // If trip is "started" but we already have an activity, show as "in_progress"
                let statusOverride = (trip.status == .started) ? "in_progress" : nil
                TripLiveActivityManager.shared.updateActivity(trip: trip, statusOverride: statusOverride)
            }

        case .completed:
            TripLiveActivityManager.shared.endActivity(status: "completed")
        case .canceled:
            TripLiveActivityManager.shared.endActivity(status: "canceled")
        case .expired:
            TripLiveActivityManager.shared.endActivity(status: "expired")
        default:
            break
        }
    }
}
