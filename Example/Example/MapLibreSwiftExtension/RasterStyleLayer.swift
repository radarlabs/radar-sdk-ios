//
//  RasterStyleLayer.swift
//  Example
//
//  Created by ShiCheng Lu on 10/29/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import InternalUtils
import MapLibre
import MapLibreSwiftMacros
import MapLibreSwiftUI
import MapLibreSwiftDSL

public struct RasterStyleLayer: SourceBoundVectorStyleLayerDefinition {
    public let identifier: String
    public let sourceLayerIdentifier: String?
    public var insertionPosition: LayerInsertionPosition = .above(.all)
    public var isVisible: Bool = true
    public var maximumZoomLevel: Float?
    public var minimumZoomLevel: Float?

    public var source: StyleLayerSource
    public var predicate: NSPredicate?

    public init(identifier: String, source: Source) {
        self.identifier = identifier
        self.source = .source(source)
        sourceLayerIdentifier = nil
    }

    public func makeStyleLayer(style: MLNStyle) -> StyleLayer {
        let tmpSource: MLNSource

        switch source {
        case let .source(s):
            let source = s.makeMGLSource()
            tmpSource = source
        case let .mglSource(s):
            tmpSource = s
        }

        let styleSource = addSourceIfNecessary(tmpSource, to: style)
print("Making style layer")
        return RasterStyleLayerInternal(definition: self, mglSource: styleSource)
    }

    // MARK: - Modifiers
}

private struct RasterStyleLayerInternal: StyleLayer {
    private var definition: RasterStyleLayer
    private let mglSource: MLNSource

    var identifier: String { definition.identifier }
    var insertionPosition: LayerInsertionPosition {
        get { definition.insertionPosition }
        set { definition.insertionPosition = newValue }
    }

    var isVisible: Bool {
        get { definition.isVisible }
        set { definition.isVisible = newValue }
    }

    var maximumZoomLevel: Float? {
        get { definition.maximumZoomLevel }
        set { definition.maximumZoomLevel = newValue }
    }

    var minimumZoomLevel: Float? {
        get { definition.minimumZoomLevel }
        set { definition.minimumZoomLevel = newValue }
    }

    init(definition: RasterStyleLayer, mglSource: MLNSource) {
        self.definition = definition
        self.mglSource = mglSource
    }

    func makeMLNStyleLayer() -> MLNStyleLayer {
        let result = MLNRasterStyleLayer(identifier: identifier, source: mglSource)
//        result.sourceLayerIdentifier = definition.sourceLayerIdentifier
//        result.circleRadius = definition.radius
//        result.circleColor = definition.color

//        result.circleStrokeWidth = definition.strokeWidth
//        result.circleStrokeColor = definition.strokeColor

//        result.predicate = definition.predicate

        
print("gave an MLN layer")
        
        return result
    }
}
