import CoreLocation
import Foundation

/// Swift-only storage used by Codable models. The Objective-C facade below remains the public
/// `RadarCoordinate` class declared in the handwritten header.
struct RadarCoordinateSwift: Codable, Sendable, Equatable {
    static let codingStrategy = CodingUserInfoKey(rawValue: "coordinateDecodingStrategy")!

    enum CodingStrategy: Sendable {
        case lngLatArray
        case latLngDictionary
    }

    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    init?(object: Any?) {
        guard let dictionary = object as? [String: Any],
            let coordinates = dictionary["coordinates"] as? [Double],
            coordinates.count == 2
        else {
            return nil
        }
        self.init(latitude: coordinates[1], longitude: coordinates[0])
    }

    static func coordinatesFrom(object: Any) -> [RadarCoordinateSwift]? {
        guard let objects = object as? [Any] else {
            return nil
        }
        let coordinates = objects.compactMap(RadarCoordinateSwift.init)
        return coordinates.count == objects.count ? coordinates : nil
    }

    func dictionaryValue() -> [String: Any] {
        [
            "type": "Point",
            "coordinates": [longitude, latitude],
        ]
    }

    func valueEquals(_ other: RadarCoordinateSwift) -> Bool {
        latitude == other.latitude && longitude == other.longitude
    }

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    init(from decoder: Decoder) throws {
        let strategy = decoder.userInfo[Self.codingStrategy] as? CodingStrategy
        if strategy == .lngLatArray {
            var container = try decoder.unkeyedContainer()
            longitude = try container.decode(Double.self)
            latitude = try container.decode(Double.self)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            latitude = try container.decode(Double.self, forKey: .latitude)
            longitude = try container.decode(Double.self, forKey: .longitude)
        }
    }

    func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[Self.codingStrategy] as? CodingStrategy
        if strategy == .lngLatArray {
            var container = encoder.unkeyedContainer()
            try container.encode(longitude)
            try container.encode(latitude)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

@objc @implementation extension RadarCoordinate {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()

    override init() {
        super.init()
    }

    init?(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        [
            "type": "Point",
            "coordinates": [coordinate.longitude, coordinate.latitude],
        ]
    }
}

extension RadarCoordinate {
    /// Keeps the SDK-only GeoJSON parser available without adding it to the public header.
    @objc(initWithObject:)
    convenience init?(object: Any?) {
        guard let dictionary = object as? [String: Any],
            let coordinates = dictionary["coordinates"] as? [Double],
            coordinates.count == 2
        else {
            return nil
        }
        self.init(coordinate: CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0]))
    }

    /// Keeps the SDK-only array parser available without adding it to the public header.
    @objc(coordinatesFromObject:)
    class func coordinatesFrom(object: Any) -> [RadarCoordinate]? {
        guard let objects = object as? [Any] else {
            return nil
        }
        let coordinates = objects.compactMap { RadarCoordinate(object: $0) }
        return coordinates.count == objects.count ? coordinates : nil
    }
}
