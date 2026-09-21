import Foundation

// swiftlint:disable identifier_name

extension RadarRevealRiskLevel {
    init(string: String) {
        switch string {
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        default: self = .none
        }
    }
}

private struct RevealRiskTokenPayload: Decodable {
    let id: String
    let token: String?
    let expiresAt: Date?
    let expiresIn: Double?
    let risk: RiskPayload
    let network: NetworkPayload
    let device: DevicePayload

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case token
        case expiresAt
        case expiresIn
        case risk
        case network
        case device
    }
}

private struct RiskPayload: Decodable {
    let level: String
    let reasons: [String]
}

private struct NetworkPayload: Decodable {
    let ipAddress: IpAddressPayload?
    let privacy: PrivacyPayload?
    let asn: AsnPayload?
}

private struct AsnPayload: Decodable {
    let asn: String?
    let country: String?
    let domain: String?
    let name: String?
    let network: String?
    let type: String?
}

private struct IpAddressPayload: Decodable {
    let ip: String?
    let countryCode: String?
    let country: String?
    let countryFlag: String?
    let state: String?
    let city: String?
    let postalCode: String?
    let latitude: Double?
    let longitude: Double?
    let connectionType: String?
    let stateCode: String?
    let stateConfidence: String?
    let countryConfidence: String?
    let dma: String?
    let dmaCode: String?
    let stateAllowed: Bool?
    let countryAllowed: Bool?
    let layer: String?
    let geometry: GeometryPayload?
}

private struct GeometryPayload: Decodable {
    let type: String
    let coordinates: [Double]
}

private struct PrivacyPayload: Decodable {
    let hosting: Bool?
    let proxy: Bool?
    let relay: Bool?
    let service: String?
    let tor: Bool?
    let vpn: Bool?
    let residentialProxy: Bool?
}

private struct DevicePayload: Decodable {
    let deviceId: String?
    let deviceType: String?
    let deviceMake: String?
    let deviceModel: String?
    let deviceOSName: String?
    let deviceOSVersion: String?
    let sdkVersion: String?
    let xPlatformType: String?
    let installId: String?
    let appId: String?
    let appName: String?
    let appVersion: String?
    let appBuild: String?
}

@objc @implementation extension RadarRevealRiskTokenRisk {
    var level: RadarRevealRiskLevel = .none
    var reasons: [String] = []

    override init() {
        super.init()
    }
}

extension RadarRevealRiskTokenRisk {
    fileprivate convenience init(payload: RiskPayload) {
        self.init()
        level = RadarRevealRiskLevel(string: payload.level)
        reasons = payload.reasons
    }
}

@objc @implementation extension RadarRevealRiskTokenNetworkAsn {
    var asn: String?
    var country: String?
    var domain: String?
    var name: String?
    var network: String?
    var type: String?

    override init() {
        super.init()
    }
}

extension RadarRevealRiskTokenNetworkAsn {
    fileprivate convenience init(payload: AsnPayload) {
        self.init()
        asn = payload.asn
        country = payload.country
        domain = payload.domain
        name = payload.name
        network = payload.network
        type = payload.type
    }
}

@objc @implementation extension RadarRevealRiskIpGeometry {
    var type = ""
    var coordinates: [NSNumber] = []

    override init() {
        super.init()
    }
}

extension RadarRevealRiskIpGeometry {
    fileprivate convenience init(payload: GeometryPayload) {
        self.init()
        type = payload.type
        coordinates = payload.coordinates.map(NSNumber.init(value:))
    }
}

@objc @implementation extension RadarRevealRiskTokenNetworkIpAddress {
    private final var ipValue: String?
    var countryCode: String?
    var country: String?
    var countryFlag: String?
    var state: String?
    var city: String?
    var postalCode: String?
    var latitude: NSNumber?
    var longitude: NSNumber?
    var connectionType: String?
    var stateCode: String?
    var stateConfidence: String?
    var countryConfidence: String?
    var dma: String?
    var dmaCode: String?
    var stateAllowed = false
    var countryAllowed = false
    var layer: String?
    var geometry: RadarRevealRiskIpGeometry?

    override init() {
        super.init()
    }
}

extension RadarRevealRiskTokenNetworkIpAddress {
    fileprivate convenience init(payload: IpAddressPayload) {
        self.init()
        ipValue = payload.ip
        countryCode = payload.countryCode
        country = payload.country
        countryFlag = payload.countryFlag
        state = payload.state
        city = payload.city
        postalCode = payload.postalCode
        latitude = payload.latitude.map(NSNumber.init(value:))
        longitude = payload.longitude.map(NSNumber.init(value:))
        connectionType = payload.connectionType
        stateCode = payload.stateCode
        stateConfidence = payload.stateConfidence
        countryConfidence = payload.countryConfidence
        dma = payload.dma
        dmaCode = payload.dmaCode
        stateAllowed = payload.stateAllowed ?? false
        countryAllowed = payload.countryAllowed ?? false
        layer = payload.layer
        geometry = payload.geometry.map(RadarRevealRiskIpGeometry.init)
    }
}

@objc @implementation extension RadarRevealRiskTokenNetworkPrivacy {
    var hosting = false
    var proxy = false
    var relay = false
    var service: String?
    var tor = false
    var vpn = false
    var residentialProxy = false

    override init() {
        super.init()
    }
}

extension RadarRevealRiskTokenNetworkPrivacy {
    fileprivate convenience init(payload: PrivacyPayload) {
        self.init()
        hosting = payload.hosting ?? false
        proxy = payload.proxy ?? false
        relay = payload.relay ?? false
        service = payload.service
        tor = payload.tor ?? false
        vpn = payload.vpn ?? false
        residentialProxy = payload.residentialProxy ?? false
    }
}

@objc @implementation extension RadarRevealRiskTokenNetwork {
    var ipAddress: RadarRevealRiskTokenNetworkIpAddress?
    var privacy: RadarRevealRiskTokenNetworkPrivacy?
    var asn: RadarRevealRiskTokenNetworkAsn?

    override init() {
        super.init()
    }
}

extension RadarRevealRiskTokenNetwork {
    fileprivate convenience init(payload: NetworkPayload) {
        self.init()
        ipAddress = payload.ipAddress.map(RadarRevealRiskTokenNetworkIpAddress.init)
        privacy = payload.privacy.map(RadarRevealRiskTokenNetworkPrivacy.init)
        asn = payload.asn.map(RadarRevealRiskTokenNetworkAsn.init)
    }
}

@objc @implementation extension RadarRevealRiskTokenDevice {
    var deviceId: String?
    var deviceType: String?
    var deviceMake: String?
    var deviceModel: String?
    var deviceOSName: String?
    var deviceOSVersion: String?
    var sdkVersion: String?
    var xPlatformType: String?
    var installId: String?
    var appId: String?
    var appName: String?
    var appVersion: String?
    var appBuild: String?

    override init() {
        super.init()
    }
}

extension RadarRevealRiskTokenDevice {
    fileprivate convenience init(payload: DevicePayload) {
        self.init()
        deviceId = payload.deviceId
        deviceType = payload.deviceType
        deviceMake = payload.deviceMake
        deviceModel = payload.deviceModel
        deviceOSName = payload.deviceOSName
        deviceOSVersion = payload.deviceOSVersion
        sdkVersion = payload.sdkVersion
        xPlatformType = payload.xPlatformType
        installId = payload.installId
        appId = payload.appId
        appName = payload.appName
        appVersion = payload.appVersion
        appBuild = payload.appBuild
    }
}

@objc @implementation extension RadarRevealRiskToken {
    @objc(_id) var _id: String! = nil
    var token: String?
    var expiresAt: Date?
    var expiresIn: NSNumber?
    var risk = RadarRevealRiskTokenRisk()
    var network = RadarRevealRiskTokenNetwork()
    var device = RadarRevealRiskTokenDevice()
    final var rawDictionary: [String: Sendable]?

    override init() {
        super.init()
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        rawDictionary ?? [:]
    }
}

extension RadarRevealRiskToken {
    var id: String { _id }

    fileprivate convenience init(payload: RevealRiskTokenPayload) {
        self.init()
        _id = payload.id
        token = payload.token
        expiresAt = payload.expiresAt
        expiresIn = payload.expiresIn.map(NSNumber.init(value:))
        risk = RadarRevealRiskTokenRisk(payload: payload.risk)
        network = RadarRevealRiskTokenNetwork(payload: payload.network)
        device = RadarRevealRiskTokenDevice(payload: payload.device)
    }

    /// Parses a Reveal Risk response while keeping Codable payload types separate from the
    /// Objective-C classes that form the public SDK surface.
    static func fromData(_ data: Data) -> RadarRevealRiskToken? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }

        guard let payload = try? decoder.decode(RevealRiskTokenPayload.self, from: data) else {
            return nil
        }
        let token = RadarRevealRiskToken(payload: payload)
        var dictionary: [String: Sendable]? = (try? JSONSerialization.jsonObject(with: data)) as? [String: Sendable]
        dictionary?["meta"] = nil
        token.rawDictionary = dictionary
        return token
    }
}

extension RadarRevealRiskToken: @unchecked Sendable {}
extension RadarRevealRiskTokenRisk: @unchecked Sendable {}
extension RadarRevealRiskTokenNetwork: @unchecked Sendable {}
extension RadarRevealRiskTokenNetworkAsn: @unchecked Sendable {}
extension RadarRevealRiskTokenNetworkIpAddress: @unchecked Sendable {}
extension RadarRevealRiskIpGeometry: @unchecked Sendable {}
extension RadarRevealRiskTokenNetworkPrivacy: @unchecked Sendable {}
extension RadarRevealRiskTokenDevice: @unchecked Sendable {}

// swiftlint:enable identifier_name
