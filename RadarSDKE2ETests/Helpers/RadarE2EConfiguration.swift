import CoreLocation
import Foundation

struct RadarE2EConfiguration {
    let baseURL: URL
    let publishableKey: String

    static let location = CLLocation(latitude: 40.78382, longitude: -73.97536)

    init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        guard let rawURL = environment["RADAR_E2E_BASE_URL"], let baseURL = URL(string: rawURL) else {
            throw ConfigurationError.invalidBaseURL
        }
        guard let publishableKey = environment["RADAR_E2E_PUBLISHABLE_KEY"] else {
            throw ConfigurationError.invalidPublishableKey
        }
        let isLoopback = baseURL.host == "localhost" || baseURL.host == "127.0.0.1"
        guard baseURL.host != nil, baseURL.scheme == "https" || (baseURL.scheme == "http" && isLoopback),
            baseURL.path.isEmpty || baseURL.path == "/", baseURL.query == nil, baseURL.fragment == nil,
            baseURL.user == nil, baseURL.password == nil
        else {
            throw ConfigurationError.invalidBaseURL
        }
        guard publishableKey.hasPrefix("prj_test_pk_"), publishableKey.count > "prj_test_pk_".count else {
            throw ConfigurationError.invalidPublishableKey
        }
        self.baseURL = baseURL
        self.publishableKey = publishableKey
    }

    private enum ConfigurationError: LocalizedError {
        case invalidBaseURL
        case invalidPublishableKey

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL: "RADAR_E2E_BASE_URL must be an HTTPS origin or a loopback HTTP origin."
            case .invalidPublishableKey: "Set RADAR_E2E_PUBLISHABLE_KEY to a test publishable key."
            }
        }
    }
}
