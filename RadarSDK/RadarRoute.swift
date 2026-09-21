import CoreLocation
import Foundation

struct RadarRouteValue: Codable, Sendable {
    struct Distance: Codable {
        let value: Double
        let text: String
    }

    struct Duration: Codable {
        let value: Double
        let text: String
    }

    struct Geometry: Codable {
        let coordinates: [RadarCoordinateSwift]
    }

    let distance: Distance
    let duration: Duration
    let geometry: Geometry?
}

private let emptyRoute = RadarRouteValue(
    distance: RadarRouteValue.Distance(value: 0, text: ""),
    duration: RadarRouteValue.Duration(value: 0, text: ""),
    geometry: nil)

@objc @implementation extension RadarRouteDistance {
    private final var route = emptyRoute

    var value: Double { route.distance.value }
    var text: String { route.distance.text }

    override init() {
        super.init()
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        RadarUtils.dictionary(from: route.distance) ?? [:]
    }
}

extension RadarRouteDistance {
    convenience init(route: RadarRouteValue) {
        self.init()
        self.route = route
    }

    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dictionary = object as? [String: Any],
            let value = dictionary["value"] as? Double,
            let text = dictionary["text"] as? String
        else {
            return nil
        }
        self.init(
            route: RadarRouteValue(
                distance: RadarRouteValue.Distance(value: value, text: text),
                duration: RadarRouteValue.Duration(value: 0, text: ""),
                geometry: RadarRouteValue.Geometry(coordinates: [])
            )
        )
    }
}

@objc @implementation extension RadarRouteDuration {
    private final var route = emptyRoute

    var value: Double { route.duration.value }
    var text: String { route.duration.text }

    override init() {
        super.init()
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        RadarUtils.dictionary(from: route.duration) ?? [:]
    }
}

extension RadarRouteDuration {
    convenience init(route: RadarRouteValue) {
        self.init()
        self.route = route
    }
}

@objc @implementation extension RadarRouteGeometry {
    private final var route = emptyRoute

    var coordinates: [RadarCoordinate]? {
        route.geometry?.coordinates.compactMap { RadarCoordinate(coordinate: $0.clLocationCoordinate2D) }
    }

    override init() {
        super.init()
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        [
            "type": "LineString",
            "coordinates": (coordinates ?? []).map { [$0.coordinate.longitude, $0.coordinate.latitude] },
        ]
    }
}

extension RadarRouteGeometry {
    convenience init?(route: RadarRouteValue) {
        guard route.geometry != nil else {
            return nil
        }
        self.init()
        self.route = route
    }
}

@objc @implementation extension RadarRoute {
    private final var route = emptyRoute
    private final var hasGeometry = false

    var distance = RadarRouteDistance()
    var duration = RadarRouteDuration()
    var geometry = RadarRouteGeometry()

    override init() {
        super.init()
        distance = RadarRouteDistance(route: emptyRoute)
        duration = RadarRouteDuration(route: emptyRoute)
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "distance": distance.dictionaryValue(),
            "duration": duration.dictionaryValue(),
        ]
        if hasGeometry {
            dictionary["geometry"] = geometry.dictionaryValue()
        }
        return dictionary
    }
}

extension RadarRoute {
    convenience init(route: RadarRouteValue) {
        self.init()
        self.route = route
        hasGeometry = route.geometry != nil
        distance = RadarRouteDistance(route: route)
        duration = RadarRouteDuration(route: route)
        geometry = RadarRouteGeometry(route: route) ?? RadarRouteGeometry()
    }

    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dictionary = object as? [String: Any] else {
            return nil
        }

        let jsonString = RadarUtils.dictionaryToJson(dictionary)
        let decoder = JSONDecoder()
        decoder.userInfo[RadarCoordinateSwift.codingStrategy] = RadarCoordinateSwift.CodingStrategy.lngLatArray

        guard let data = jsonString.data(using: .utf8),
            let route = try? decoder.decode(RadarRouteValue.self, from: data)
        else {
            return nil
        }
        self.init(route: route)
    }
}
