import Foundation

extension RadarTripOptions {
    static func parsed(from dictionary: [AnyHashable: Any]?) -> RadarTripOptions? {
        guard let dictionary else {
            return nil
        }

        let externalId = dictionary["externalId"] as? String ?? ""
        let destinationGeofenceTag = dictionary["destinationGeofenceTag"] as? String
        let destinationGeofenceExternalId = dictionary["destinationGeofenceExternalId"] as? String
        let scheduledArrivalAt = Self.scheduledArrival(from: dictionary["scheduledArrivalAt"])
        let mode = Self.mode(from: dictionary["mode"] as? String)
        let approachingThreshold = (dictionary["approachingThreshold"] as? NSNumber)?.uint16Value ?? 0
        let startTracking = Self.startTracking(from: dictionary["startTracking"])
        let legs = (dictionary["legs"] as? [Any]).flatMap(RadarTripLeg.legs(from:))

        let options = RadarTripOptions()
        options.externalId = externalId
        options.destinationGeofenceTag = destinationGeofenceTag
        options.destinationGeofenceExternalId = destinationGeofenceExternalId
        options.scheduledArrivalAt = scheduledArrivalAt
        options.mode = mode
        options.approachingThreshold = approachingThreshold
        options.startTracking = startTracking
        options.legs = legs
        options.metadata = dictionary["metadata"] as? [AnyHashable: Any]
        return options
    }
}
