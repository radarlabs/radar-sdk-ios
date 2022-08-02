//
//  AppDelegate.swift
//  Example
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import UIKit
import RadarSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let locationManager = CLLocationManager()

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = EventTableViewController(style: .plain)
        self.window?.makeKeyAndVisible()

        locationManager.delegate = self
        requestLocationPermissions()

        return true
    }

    func runDemo() {
        initializeSDK()

        foregroundTracking()
        backgroundTrackingForGeofencing()
        backgroundTrackingForTrips()
        mockTrackingForTesting()
        manualTracking()
        identifyUser()

        // Other APIs
        getLocation()
        context()
        geocoding()
        search()
        distance()
        matrix()
        customEvents()
    }

    /// When your app starts, initialize the SDK with your publishable API key,
    /// found on the [Settings page](https://radar.com/dashboard/settings).
    ///
    /// Use your Test Publishable key for testing and non-production
    /// environments. Use your Live Publishable key for production environments.
    ///
    /// **Note that you should always use your publishable API keys, which are
    /// restricted in scope, in the SDK. Do not use your secret API keys, which
    /// are unrestricted in scope, in any client-side code.**
    ///
    /// @see https://radar.com/documentation/sdk/ios#initialize-sdk
    /// @see https://radar.com/documentation/sdk/ios#listening-for-events-with-a-delegate
    func initializeSDK() {
        // Initialize SDK
        // https://radar.com/documentation/sdk/ios#initialize-sdk
        // Replace with a valid test publishable key
        Radar.initialize(publishableKey: "prj_test_pk_0000000000000000000000000000000000000000")

        // To listen for events, location updates, and errors client-side, set
        // a RadarDelegate. Set your RadarDelegate in a codepath that will be
        // initialized and executed in the background. For example, make your
        // AppDelegate implement RadarDelegate, not a ViewController.
        // AppDelegate will be initialized in the background, whereas a
        // ViewController may not be.
        Radar.setDelegate(self)
    }

    /// Once the user has granted foreground permissions, you can track the
    /// user's location in the foreground. You may provide an optional
    /// `completionHandler` that receives the request status, the user's
    /// location, the events generated, if any, and the user.
    ///
    /// @see https://radar.com/documentation/sdk/ios#foreground-tracking
    func foregroundTracking() {
        if UIApplication.shared.applicationState != .background {
            Radar.trackOnce { (status, location, events, user) in
                print("Track once: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
            }
        }

    }

    /// Once you have initialized the SDK and the user has authorized
    /// background permissions, you can start tracking the user's location in
    /// the background.
    ///
    /// The SDK supports custom tracking options as well as three presets.
    ///
    /// For geofencing, we recommend using
    /// `RadarTrackingOptions.presetResponsive`. This preset detects whether
    /// the device is stopped or moving. When moving, it tells the SDK to send
    /// location updates to the server every 2-3 minutes. When stopped, it
    /// tells the SDK to shut down to save battery. Once stopped, the device
    /// will need to move more than 100 meters to wake up and start moving
    /// again.
    ///
    /// Assuming the user has authorized background permissions, background
    /// tracking will work even if the app has been backgrounded or killed, as
    /// iOS location services will wake up the app to deliver events.
    ///
    /// **Note that location updates may be delayed by if the device has
    /// connectivity issues, low battery, or wi-fi disabled.**
    ///
    /// **Though we recommend using presets for most use cases, you can modify
    /// the presets.** See the [tracking options
    /// reference](https://radar.com/documentation/sdk/tracking).
    ///
    /// @see https://radar.com/documentation/sdk/ios#background-tracking-for-geofencing
    func backgroundTrackingForGeofencing() {
        Radar.startTracking(trackingOptions: RadarTrackingOptions.presetResponsive)
    }

    /// For trips, we recommend using `RadarTrackingOptions.presetContinuous`.
    /// This preset tells the SDK to send location updates to the server every
    /// 30 seconds, regardless of whether the device is moving.
    ///
    /// **By default, this preset shows the flashing blue status bar while
    /// tracking. If the flashing blue status bar is shown, only foreground
    /// permissions are required for tracking.**
    ///
    /// Learn more about starting, completing, and canceling trips in the [trip
    /// tracking documentation](https://radar.com/documentation/trip-tracking).
    ///
    /// **Don't forget!** You can always find your user on the [Users
    /// page](https://radar.com/dashboard/users) or events on the [Events
    /// page](https://radar.com/dashboard/events)). To trigger an event, you'll
    /// need to [create a geofence](https://radar.com/geofences) or [start a
    /// trip](https://radar.com/documentation/trip-tracking) if you haven't
    /// already. Also, check your device settings to make sure you've granted
    /// location permissions.
    ///
    /// @see https://radar.com/documentation/sdk/ios#background-tracking-for-trips
    /// @see https://radar.com/documentation/trip-tracking
    func backgroundTrackingForTrips() {
        // Starting trips
        // When a order starts or the user taps "I'm on my way," start
        // tracking and start a trip with an ID, a destination geofence, a
        // travel mode, and custom metadata (e.g., customer name, car model,
        // or license plate) depending on your use case.
        let tripOptions = RadarTripOptions(externalId: "299", destinationGeofenceTag: "store", destinationGeofenceExternalId: "123")
        tripOptions.mode = .car
        tripOptions.metadata = [
            "Customer Name": "Jacob Pena",
            "Car Model": "Green Honda Civic"
        ]
        Radar.startTrip(options: tripOptions)
        Radar.startTracking(trackingOptions: .presetContinuous)

        // Updating trips
        // As trips progress, you can pass updates about the trip. This is
        // commonly used to capture additional metadata as the trip progresses
        // (i.e. in a pickup use case, car info provided on arrival), but can
        // also be used to progress the trip status manually. The trip-tracking
        // dashboard, available on the Enterprise, can receive notifications
        // when trip metadata changes occur.
        if let updatedTripOptions = Radar.getTripOptions() {
            updatedTripOptions.metadata = [
                "Parking Spot": "1",
            ]
            Radar.updateTrip(options: updatedTripOptions, status: RadarTripStatus.arrived)
        }

        // Ending trips
        // When the order is cancelled or picked up, stop tracking and stop
        // the trip. This can be done either via the SDK or through Radar APIs.
        //
        // The Radar settings page also allows for trip expiration based on a
        // set number of hours after trip start. For organizations on the Radar
        // Enterprise plan, there is the ability to also automatically complete
        // trips based on a configurable ETA following destination arrival.

        // order picked up or user taps "I'm here"
        Radar.completeTrip()

        // Order cancelled
        // Radar.cancelTrip()

        // Stop tracking
        Radar.stopTracking()
    }

    /// Can't go for a walk or a drive? You can simulate a sequence of location
    /// updates. For example, simulate a sequence of 10 location updates every
    /// 3 seconds by car from an origin to a destination.
    ///
    /// @see https://radar.com/documentation/sdk/ios#mock-tracking-for-testing
    func mockTrackingForTesting() {
        var i = 0

        Radar.mockTracking(
            origin: CLLocation(latitude: 40.714708, longitude: -74.035807),
            destination: CLLocation(latitude: 40.717410, longitude: -74.053334),
            mode: .car,
            steps: 10,
            interval: 3) { (status: RadarStatus, location: CLLocation?, events: [RadarEvent]?, user: RadarUser?) in
                print("Mock track: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")

                if (i == 2) {
                    Radar.completeTrip()
                }

                i += 1
            }
    }

    /// If you want to manage location services yourself, you can manually
    /// update the user's location.
    ///
    /// @see https://radar.com/documentation/sdk/ios#manual-tracking
    func manualTracking() {
        let location = CLLocation(latitude: 40.7344, longitude: -73.9912)
        Radar.trackOnce(location: location) { (status: RadarStatus, location: CLLocation?, events: [RadarEvent]?, user: RadarUser?) in
            print("Track once with manual location: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
        }
    }

    /// The SDK automatically generates a unique `installId` on every fresh
    /// install. Radar creates a new user record for every unique `installId`.
    ///
    /// In addition, you can use other identifiers to identify the user.
    ///
    /// Radar will automatically identify the user by `deviceId` ([IDFV](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor)).
    ///
    /// @see https://radar.com/documentation/sdk/ios#identify-user
    /// @see https://radar.com/documentation/faqs#what-are-privacy-best-practices-for-radar
    func identifyUser() {
        // To set a custom userId, call this, where userId is a stable unique
        // ID for the user.
        // Do not send any PII, like names, email addresses, or publicly
        // available IDs, for userId. See privacy best practices for more
        // information.
        // Radar.setUserId("someUniqueUserID") // uncomment this to change it

        // To set a dictionary of custom metadata for the user, call this,
        // where metadata is a dictionary with up to 16 keys and values of type
        // string, boolean, or number.
        Radar.setMetadata(["orderNumber": 1564, "preferredPaymentType": "credit"])

        // Finally, to set an optional description for the user, displayed in
        // the dashboard, call:
        Radar.setDescription("Radar Example App custom description")

        // You only need to call these methods once, as these settings will be
        // persisted across app sessions.
    }

    // MARK: - Other APIs

    /// If the user has granted location permissions, you can range and monitor
    /// beacons.
    ///
    /// @see https://radar.com/documentation/sdk/ios#beacons
    func beacons() {
        // To range beacons in the foreground, call:
        Radar.trackOnce(desiredAccuracy: .high, beacons: true) { (status: RadarStatus, location: CLLocation?, events: [RadarEvent]?, user: RadarUser?) in
            // do something with user.beacons
        }

        // To monitor beacons in the background, update your tracking options:
        let trackingOptions = RadarTrackingOptions.presetResponsive
        trackingOptions.beacons = true
        Radar.startTracking(trackingOptions: trackingOptions)
        Radar.stopTracking()
    }

    /// Get a single location update without sending it to the server.
    ///
    /// @see https://radar.com/documentation/sdk/ios#get-location
    func getLocation() {
        if UIApplication.shared.applicationState != .background {
            Radar.getLocation { (status: RadarStatus, location: CLLocation?, stopped: Bool) in
                print("Location: status = \(Radar.stringForStatus(status)); location = \(String(describing: location))")
            }
        }
    }

    /// With the [context API](https://radar.com/documentation/api#context), get
    /// context for a location without sending device or user identifiers to the
    /// server.
    ///
    /// @see https://radar.com/documentation/sdk/ios#context
    func context() {
        Radar.getContext { (status: RadarStatus, location: CLLocation?, context: RadarContext?) in
            print("Context: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); context?.geofences = \(String(describing: context?.geofences)); context?.place = \(String(describing: context?.place)); context?.country = \(String(describing: context?.country))")
        }
    }

    /// @see https://radar.com/documentation/sdk/ios#geocoding
    /// @see https://radar.com/documentation/api#forward-geocode
    /// @see https://radar.com/documentation/api#reverse-geocode
    /// @see https://radar.com/documentation/api#ip-geocode
    func geocoding() {
        // With the forward geocoding API, geocode an address, converting
        // address to coordinates:
        Radar.geocode(address: "841 broadway manhattan") { (status, addresses) in
            print("Forward geocode: status = \(Radar.stringForStatus(status)); coordinate = \(String(describing: addresses?.first?.coordinate))")
        }

        // With the reverse geocoding API, reverse geocode a location,
        // converting coordinates to address:
        let location = CLLocation(latitude: 40.7344, longitude: -73.9912)
        Radar.reverseGeocode(location: location) { (status: RadarStatus, addresses: [RadarAddress]?) in
            print("Reverse geocode: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
        }

        // With the IP geocoding API, geocode the device's current IP address,
        // converting IP address to city, state, and country:
        Radar.ipGeocode { (status: RadarStatus, address: RadarAddress?, proxy: Bool) in
            print("IP geocode: status = \(Radar.stringForStatus(status)); country = \(String(describing: address?.countryCode)); city = \(String(describing: address?.city)); proxy = \(proxy)")
        }
    }

    /// @see https://radar.com/documentation/sdk/ios#search
    func search() {
        Radar.searchPlaces(
            radius: 1000,
            chains: ["mcdonalds"],
            categories: nil,
            groups: nil,
            limit: 10
        ) { (status, location, places) in
            print("Search places: status = \(Radar.stringForStatus(status)); places = \(String(describing: places))")
        }

        Radar.searchGeofences(
            radius: 1000,
            tags: ["store"],
            metadata: nil,
            limit: 10
        ) { (status, location, geofences) in
            print("Search geofences: status = \(Radar.stringForStatus(status)); geofences = \(String(describing: geofences))")
        }

        let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)

        Radar.autocomplete(
            query: "brooklyn",
            near: origin,
            layers: ["locality"],
            limit: 10,
            country: "US"
        ) { (status, addresses) in
            print("Autocomplete: status = \(Radar.stringForStatus(status)); formattedAddress = \(String(describing: addresses?.first?.formattedAddress))")
        }
    }

    func customEvents() {
        Radar.sendEvent(customType: "custom_event", metadata: ["data": "test"]) { (status, location, events, user) in
            if let customEvent = events?.first,
               customEvent.type == .custom {
                print("Custom type: \(customEvent.customType!)")
            }

            print("Send event: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
        }

        // Test custom event with a manual location
        let customLocation = CLLocation(latitude: 38.87896275702961, longitude: -77.18228972761578)

        Radar.sendEvent(customType: "custom_event_with_location", location: customLocation, metadata: ["data": "test"]) { (status, location, events, user) in
            if let customEvent = events?.first,
               customEvent.type == .custom {
                print("Custom type: \(customEvent.customType!)")
            }

            print("Send event with custom location: status = \(Radar.stringForStatus(status)); location = \(String(describing: location)); events = \(String(describing: events)); user = \(String(describing: user))")
        }
    }

    /// With the [distance API](https://radar.com/documentation/api#distance),
    /// calculate the travel distance and duration between an origin and a
    /// destination:
    ///
    /// @see https://radar.com/documentation/sdk/ios#distance
    func distance() {
        let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
        let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)
        Radar.getDistance(origin: origin,
                          destination: destination,
                          modes: [.foot, .car],
                          units: .imperial
        ) { (status: RadarStatus, routes: RadarRoutes?) in
            print("Distance: status = \(Radar.stringForStatus(status)); routes.car.distance.value = \(String(describing: routes?.car?.distance.value)); routes.car.distance.text = \(String(describing: routes?.car?.distance.text)); routes.car.duration.value = \(String(describing: routes?.car?.duration.value)); routes.car.duration.text = \(String(describing: routes?.car?.duration.text))")
        }
    }

    /// @see https://radar.com/documentation/sdk/ios#matrix
    func matrix() {
        let origins = [
            CLLocation(latitude: 40.78382, longitude: -73.97536),
            CLLocation(latitude: 40.70390, longitude: -73.98670)
        ]
        let destinations = [
            CLLocation(latitude: 40.64189, longitude: -73.78779),
            CLLocation(latitude: 35.99801, longitude: -78.94294)
        ]

        Radar.getMatrix(origins: origins, destinations: destinations, mode: .car, units: .imperial) { (status, matrix) in
            print("Matrix: status = \(Radar.stringForStatus(status)); matrix[0][0].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 0, destinationIndex: 0)?.duration.text)); matrix[0][1].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 0, destinationIndex: 1)?.duration.text)); matrix[1][0].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 1, destinationIndex: 0)?.duration.text)); matrix[1][1].duration.text = \(String(describing: matrix?.routeBetween(originIndex: 1, destinationIndex: 1)?.duration.text))")
        }
    }

}

// MARK: - CLLocationManagerDelegate

extension AppDelegate: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocationPermissions()

        if status == .authorizedAlways {
            runDemo()
        }
    }

    func requestLocationPermissions() {
        var status: CLAuthorizationStatus = .notDetermined
        if #available(iOS 14.0, *) {
            // On iOS 14.0 and later, use the authorizationStatus instance property.
            status = locationManager.authorizationStatus
        } else {
            // Before iOS 14.0, use the authorizationStatus class method.
            status = CLLocationManager.authorizationStatus()
        }

        if #available(iOS 13.4, *) {
            // On iOS 13.4 and later, prompt for foreground first. If granted, prompt for background. The OS will show the background prompt in-app.
            if status == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse {
                locationManager.requestAlwaysAuthorization()
            }
        } else {
            // Before iOS 13.4, prompt for background first. On iOS 13, the OS will show a foreground prompt in-app. The OS will show the background prompt outside of the app later, at a time determined by the OS.
            locationManager.requestAlwaysAuthorization()
        }
    }

}

// MARK: - RadarDelegate
// https://radar.com/documentation/sdk/ios#listening-for-events-with-a-delegate

extension AppDelegate: RadarDelegate {

    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
        for event in events {
            notify(Utils.stringForRadarEvent(event))
        }
    }

    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        let body = "\(user.stopped ? "Stopped at" : "Moved to") location (\(location.coordinate.latitude), \(location.coordinate.longitude)) with accuracy \(location.horizontalAccuracy) meters"
        notify(body)
    }

    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        let body = "\(stopped ? "Client stopped at" : "Client moved to") location (\(location.coordinate.latitude), \(location.coordinate.longitude)) with accuracy \(location.horizontalAccuracy) meters and source \(Utils.stringForRadarLocationSource(source))"
        notify(body)
    }

    func didFail(status: RadarStatus) {
        notify(Radar.stringForStatus(status))
    }

    func didLog(message: String) {
        notify(message)
    }

    func notify(_ body: String) {
        (window?.rootViewController as? EventTableViewController)?.events.append((Date(), body))
    }

}

class EventTableViewController: UITableViewController {

    var events: [(Date, String)] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override init(style: UITableView.Style) {
        super.init(style: .plain)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "eventCell")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events[events.count - indexPath.row - 1]
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        cell.textLabel?.text = event.1
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = String(describing: event.0)

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

}
