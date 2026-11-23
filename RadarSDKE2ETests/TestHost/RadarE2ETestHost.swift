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
    var window: UIWindow?
    private var scenarioStarted = false
    private var resultLabel: UILabel?
    private lazy var locationManager = CLLocationManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let controller = UIViewController()
        window.rootViewController = controller
        if ProcessInfo.processInfo.environment["RADAR_E2E_RUN_TRACK_ONCE"] == "1" {
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
            resultLabel = label
        }
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard resultLabel != nil, !scenarioStarted else { return }
        locationManager.delegate = self
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            startScenario(authorization: locationManager.authorizationStatus)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorization = manager.authorizationStatus
        Task { @MainActor in
            startScenario(authorization: authorization)
        }
    }

    private func startScenario(authorization: CLAuthorizationStatus) {
        guard authorization != .notDetermined, !scenarioStarted else { return }
        scenarioStarted = true
        Task { @MainActor in
            do {
                try await RadarTrackOnceScenario.run(configuration: RadarE2EConfiguration())
                resultLabel?.text = "Passed"
            } catch {
                resultLabel?.text = "Failed: \(error.localizedDescription)"
            }
        }
    }
}
