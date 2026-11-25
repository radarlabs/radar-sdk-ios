import Foundation

/// The fields of a logged `POST /v1/track` request body that the E2E assertions read.
struct RadarE2ETrackRequest: Decodable {
    let userId: String?
    let foreground: Bool?
    let source: String?
    let latitude: Double?
    let longitude: Double?
}

/// A GeoJSON point, as the server returns a user's location.
struct RadarE2EGeoJSONPoint: Decodable {
    /// Longitude, then latitude.
    let coordinates: [Double]?
}

/// The fields of a logged `POST /v1/track` response body that the E2E assertions read.
struct RadarE2ETrackResponse: Decodable {
    struct Meta: Decodable {
        let code: Int?
    }

    struct User: Decodable {
        let userId: String?
        let foreground: Bool?
        let source: String?
        let location: RadarE2EGeoJSONPoint?
    }

    let meta: Meta?
    let user: User?
}

/// Collects the track requests and responses the SDK writes to its debug log.
///
/// Exchanges keep only the fields the E2E assertions read. Headers, which carry the publishable key, are never stored.
struct RadarE2ETrackLog {
    struct Exchange {
        let url: String
        /// Nil when the SDK did not log the params, as for replay requests, or they did not decode.
        let request: RadarE2ETrackRequest?
        var statusCode: Int?
        /// Nil until the response is logged, or when its body did not decode.
        var response: RadarE2ETrackResponse?
    }

    private(set) var exchanges: [Exchange] = []
    private var unmatchedResponses: [Exchange] = []
    private let trackURLs: Set<String>

    init(host: String) {
        trackURLs = ["\(host)/v1/track", "\(host)/v1/track/replay"]
    }

    mutating func record(_ message: String) {
        guard message.contains("Radar API ") else { return }
        let line = Self.withoutLogSuffix(message)
        if let url = Self.text(in: line, after: "Radar API request | method = POST; url = ", before: "; headers = "), trackURLs.contains(url) {
            var exchange = Exchange(url: url, request: Self.text(in: line, after: "; params = ").flatMap(Self.decode))
            // The SDK delivers each log line in its own task, so a response can arrive before its request.
            if let index = unmatchedResponses.firstIndex(where: { $0.url == url }) {
                let early = unmatchedResponses.remove(at: index)
                exchange.statusCode = early.statusCode
                exchange.response = early.response
            }
            exchanges.append(exchange)
        } else if let url = Self.text(in: line, after: "Radar API response | method = POST; url = ", before: "; statusCode = "),
            trackURLs.contains(url),
            let status = Self.text(in: line, after: "; statusCode = ", before: ";").flatMap({ Int($0) })
        {
            let response: RadarE2ETrackResponse? = Self.text(in: line, after: "; res = ").flatMap(Self.decode)
            if let index = exchanges.firstIndex(where: { $0.url == url && $0.statusCode == nil }) {
                exchanges[index].statusCode = status
                exchanges[index].response = response
            } else {
                unmatchedResponses.append(Exchange(url: url, request: nil, statusCode: status, response: response))
            }
        }
    }

    func exchanges(since index: Int) -> [Exchange] {
        Array(exchanges.dropFirst(index))
    }

    /// The SDK logger appends ` | backgroundTimeRemaining = …` to every message it hands to the delegate.
    private static func withoutLogSuffix(_ message: String) -> String {
        guard let suffix = message.range(of: " | backgroundTimeRemaining", options: .backwards) else { return message }
        return String(message[..<suffix.lowerBound])
    }

    private static func text(in line: String, after marker: String) -> String? {
        line.range(of: marker).map { String(line[$0.upperBound...]) }
    }

    private static func text(in line: String, after marker: String, before terminator: String) -> String? {
        guard let start = line.range(of: marker),
            let end = line.range(of: terminator, range: start.upperBound..<line.endIndex)
        else { return nil }
        return String(line[start.upperBound..<end.lowerBound])
    }

    private static func decode<T: Decodable>(_ json: String) -> T? {
        try? JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
