//
//  CLLocation+Radar.swift
//  RadarSDK
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

public extension CLLocation {

    var isValid: Bool {
        let latitudeValid =  coordinate.latitude != 0 && coordinate.latitude > -90 && coordinate.latitude < 90
        let longitudeValid = coordinate.longitude != 0 && coordinate.longitude > -180 && coordinate.latitude < 180
        let horizontalAccuracyValid = horizontalAccuracy > 0

        return latitudeValid && longitudeValid && horizontalAccuracyValid
    }

}
