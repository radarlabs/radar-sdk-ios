import CoreLocation
import UIKit

@main
final class RadarE2ETestHost: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = TestHostSceneDelegate.self
        return configuration
    }
}

private final class TestHostSceneDelegate: UIResponder, UIWindowSceneDelegate, CLLocationManagerDelegate {
    /// How long to wait for an authorization change once the Always prompt closes. Choosing Change to Always Allow can reactivate the scene before the change arrives.
    private static let alwaysPromptClosedGraceSeconds = 1
    /// How long to wait for any answer to the Always prompt before running with the permission the app has.
    private static let alwaysPromptTimeoutSeconds = 15

    var window: UIWindow?
    private var resultLabel: UILabel?
    private var requestedRun: (scenario: RadarE2EScenario, permission: RadarE2EPermissionRequest)?
    private var requestedAlways = false
    private var runStarted = false
    private lazy var locationManager = CLLocationManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let controller = UIViewController()
        window.rootViewController = controller
        let environment = ProcessInfo.processInfo.environment
        if let scenarioName = environment[RadarE2EEnvironment.scenario] {
            resultLabel = addResultLabel(to: controller)
            do {
                requestedRun = try Self.parseRun(scenarioName: scenarioName, permissionName: environment[RadarE2EEnvironment.permissionRequest])
            } catch {
                show(.failed(error.localizedDescription))
            }
        }
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard requestedRun != nil, !runStarted else { return }
        locationManager.delegate = self
        if requestedAlways {
            // The scene becomes active again when the Always prompt closes. Keep Only While Using leaves the status unchanged, so no authorization change follows.
            startIfStillWaiting(afterSeconds: Self.alwaysPromptClosedGraceSeconds)
        }
        advance()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            advance()
        }
    }

    private static func parseRun(scenarioName: String, permissionName: String?) throws -> (scenario: RadarE2EScenario, permission: RadarE2EPermissionRequest) {
        guard let scenario = RadarE2EScenario(rawValue: scenarioName) else {
            throw RadarE2EFailure("Unknown scenario \(scenarioName).")
        }
        let permissionName = permissionName ?? RadarE2EPermissionRequest.noRequest.rawValue
        guard let permission = RadarE2EPermissionRequest(rawValue: permissionName) else {
            throw RadarE2EFailure("Unknown permission request \(permissionName).")
        }
        return (scenario, permission)
    }

    private func addResultLabel(to controller: UIViewController) -> UILabel {
        let label = UILabel()
        label.text = "Running"
        label.accessibilityIdentifier = "radar-e2e-result"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: controller.view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: controller.view.layoutMarginsGuide.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
        ])
        return label
    }

    /// Asks for the next permission the run needs, or starts the run once the permission state is settled.
    private func advance() {
        guard let requestedRun, !runStarted else { return }
        switch (requestedRun.permission, locationManager.authorizationStatus) {
        case (.noRequest, _):
            start(requestedRun.scenario)
        case (_, .notDetermined):
            locationManager.requestWhenInUseAuthorization()
        case (.always, .authorizedWhenInUse) where !requestedAlways:
            requestedAlways = true
            locationManager.requestAlwaysAuthorization()
            startIfStillWaiting(afterSeconds: Self.alwaysPromptTimeoutSeconds)
        case (.always, .authorizedWhenInUse):
            // Wait for the Always prompt's answer: an authorization change, the prompt closing, or the timeout.
            return
        default:
            start(requestedRun.scenario)
        }
    }

    /// Starts the run after a delay unless an authorization change starts it first.
    private func startIfStillWaiting(afterSeconds seconds: Int) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * NSEC_PER_SEC)
            guard let self, let requestedRun = self.requestedRun, !self.runStarted else { return }
            self.start(requestedRun.scenario)
        }
    }

    private func start(_ scenario: RadarE2EScenario) {
        runStarted = true
        Task { @MainActor in
            do {
                let sdk = RadarE2ESDK(configuration: try RadarE2EConfiguration())
                defer { sdk.reset() }
                show(await sdk.run(scenario))
            } catch {
                show(.failed(error.localizedDescription))
            }
        }
    }

    private func show(_ result: RadarE2EResult) {
        var result = result
        result.locationAuthorization = Self.name(of: locationManager.authorizationStatus)
        resultLabel?.text = "Done"
        resultLabel?.accessibilityValue = (try? JSONEncoder().encode(result)).flatMap { String(data: $0, encoding: .utf8) }
    }

    private static func name(of status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: "notDetermined"
        case .restricted: "restricted"
        case .denied: "denied"
        case .authorizedAlways: "authorizedAlways"
        case .authorizedWhenInUse: "authorizedWhenInUse"
        @unknown default: "unknown"
        }
    }
}
