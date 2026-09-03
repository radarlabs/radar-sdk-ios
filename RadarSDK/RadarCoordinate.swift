import CoreLocation
import Foundation


@objc(RadarCoordinate)
final class RadarCoordinateSwift: NSObject, Codable, Sendable {

    static let codingStrategy = CodingUserInfoKey(rawValue: "coordinateDecodingStrategy")!
    enum CodingStrategy: Sendable {
        case lngLatArray
        case latLngDictionary
    }

    let latitude: Double
    let longitude: Double

    @objc
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    @objc
    public init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    @objc
    internal init?(object: Any?) {
        guard let dict = object as? [String: Any] else {
            return nil
        }
        guard let coords = dict["coordinates"] as? [Double] else {
            return nil
        }
        guard coords.count == 2 else {
            return nil
        }
        self.longitude = coords[0]
        self.latitude = coords[1]
    }

    @objc
    public override init() {
        self.latitude = 0
        self.longitude = 0
    }

    @objc
    internal static func coordinatesFrom(object: Any) -> [RadarCoordinateSwift]? {
        guard let array = object as? [Any] else {
            return nil
        }
        return array.compactMap(RadarCoordinateSwift.init)
    }

    @objc
    public func dictionaryValue() -> [String: Any] {
        return [
            "type": "Point",
            "coordinates": [longitude, latitude],
        ]
    }

    // Matches what Codable synthesis produced for the previous `struct` definition,
    // so persisted state (e.g. RadarSyncState) round-trips unchanged.
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    init(from decoder: Decoder) throws {
        let strategy = decoder.userInfo[RadarCoordinateSwift.codingStrategy] as? CodingStrategy
        if strategy == CodingStrategy.lngLatArray {
            var container = try decoder.unkeyedContainer()
            self.longitude = try container.decode(Double.self)
            self.latitude = try container.decode(Double.self)
        } else {  // CodingStrategy.LatLngDictionary or default
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.latitude = try container.decode(Double.self, forKey: .latitude)
            self.longitude = try container.decode(Double.self, forKey: .longitude)
        }
    }

    func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[RadarCoordinateSwift.codingStrategy] as? CodingStrategy
        if strategy == CodingStrategy.lngLatArray {
            var container = encoder.unkeyedContainer()
            try container.encode(longitude)
            try container.encode(latitude)
        } else {  // CodingStrategy.LatLngDictionary or default
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
        }
    }

    // `==` on an NSObject subclass routes through `isEqual:`, which defaults to identity.
    // Compare values instead, matching the `Equatable` synthesis of the previous `struct`.
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RadarCoordinateSwift else {
            return false
        }
        return latitude == other.latitude && longitude == other.longitude
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(latitude)
        hasher.combine(longitude)
        return hasher.finalize()
    }
}
