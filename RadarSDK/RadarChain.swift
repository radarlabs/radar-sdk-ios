import Foundation

struct RadarChainPayload: Codable {
    let slug: String
    let name: String
    let externalId: String?
    let metadata: [String: RadarMetadataValue]?

    func makeChain() -> RadarChain {
        let foundationMetadata = metadata?.reduce(into: [AnyHashable: Any]()) { result, entry in
            result[entry.key] = entry.value.anyValue
        }
        return RadarChain(
            slug: slug,
            name: name,
            externalId: externalId,
            metadata: foundationMetadata)
    }
}

@objc @implementation extension RadarChain {
    var slug = ""
    var name = ""
    var externalId: String?
    var metadata: [AnyHashable: Any]?

    override init() {
        super.init()
    }

    @objc(arrayForChains:)
    class func array(for chains: [RadarChain]?) -> [[AnyHashable: Any]]? {
        chains?.map { $0.dictionaryValue() }
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "slug": slug,
            "name": name,
        ]
        if let externalId {
            dictionary["externalId"] = externalId
        }
        if let metadata {
            dictionary["metadata"] = metadata
        }
        return dictionary
    }
}

extension RadarChain {
    /// Keeps the SDK-only initializers available without adding them to the public header.
    @objc(initWithSlug:name:externalId:metadata:)
    convenience init(slug: String, name: String, externalId: String?, metadata: [AnyHashable: Any]?) {
        self.init()
        self.slug = slug
        self.name = name
        self.externalId = externalId
        self.metadata = metadata
    }

    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dictionary = object as? NSDictionary,
            let slug = dictionary["slug"] as? String,
            let name = dictionary["name"] as? String
        else {
            return nil
        }
        self.init(
            slug: slug,
            name: name,
            externalId: dictionary["externalId"] as? String,
            metadata: dictionary["metadata"] as? [AnyHashable: Any])
    }
}
