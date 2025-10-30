//
//  ImageSource.swift
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

public enum ImageData {
    case url(URL)
    case image(UIImage)
}

public func Quad(_ topLeft: [Double], _ bottomLeft: [Double], _ bottomRight: [Double], _ topRight: [Double]) -> MLNCoordinateQuad {
    MLNCoordinateQuadMake(
        CLLocationCoordinate2D(latitude: topLeft[0], longitude: topLeft[1]),
        CLLocationCoordinate2D(latitude: bottomLeft[0], longitude: bottomLeft[1]),
        CLLocationCoordinate2D(latitude: bottomRight[0], longitude: bottomRight[1]),
        CLLocationCoordinate2D(latitude: topRight[0], longitude: topRight[1])
    )
}

public struct ImageSource: Source {
    public let identifier: String
    let coordinateQuad: MLNCoordinateQuad
    let data: ImageData

    public init(
        identifier: String,
        coordinateQuad: MLNCoordinateQuad,
        _ makeImageData: () -> ImageData
    ) {
        self.identifier = identifier
        self.coordinateQuad = coordinateQuad
        data = makeImageData()
    }

    public func makeMGLSource() -> MLNSource {
        switch data {
        case let .url(url):
            MLNImageSource(identifier: identifier, coordinateQuad: coordinateQuad, url: url)
        case let .image(image):
            MLNImageSource(identifier: identifier, coordinateQuad: coordinateQuad, image: image)
        }
    }
}
