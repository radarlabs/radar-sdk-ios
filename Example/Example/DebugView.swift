//
//  DebugView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import CoreML
import RadarSDKIndoors
import CoreLocation
import MapLibre
import MapLibreSwiftUI
import MapLibreSwiftDSL

struct DebugView: View {
    
    @State
    var tapCoordinates = CLLocationCoordinate2D()
    
    
    var body: some View {
        VStack(spacing: 10) {
            let style = "radar-default-v1"
            let publishableKey = "prj_test_pk_c0ebf059d9895f428fac2295dbe83568507938e3"
            let styleURL = URL(string: "https://api.radar.io/maps/styles/\(style)?publishableKey=\(publishableKey)")!
            
//            MapView(styleURL: styleURL, camera: .constant(.trackUserLocation(zoom: 17))) {
//                
//                // Define a data source.
//                // It will be automatically if a layer references it.
////                let polylineSource = ShapeSource(identifier: "polyline") {
////                    MLNPolylineFeature(coordinates: )
////                }
//                let tappedPoint = ShapeSource(identifier: "tapped-point") {
//                    MLNPointFeature(coordinate: tapCoordinates)
//                }
//                
//                CircleStyleLayer(identifier: "tapped-point", source: tappedPoint)
//                    .color(.red)
//                
//                
//                let indoorMap = ImageSource(identifier: "radar-indoors-layer", coordinateQuad: Quad(
//                    [40.739176403770000, -73.98506837398742],
//                    [40.738102592955016, -73.98586187468311],
//                    [40.737476360708260, -73.98438576909109],
//                    [40.738550165730345, -73.98359224656258]
//                )) {
//                    ImageData.url(URL("https://upload.wikimedia.org/wikipedia/commons/b/b6/Image_created_with_a_mobile_phone.png")!)
//                }
//                
//                RasterStyleLayer(identifier: "radar-indoors-layer", source: indoorMap)
//                
//            }.onTapMapGesture { value in
//                tapCoordinates = value.coordinate
//            }
            
            HStack(spacing: 20) {
                Button("set") {
                    let coordinates = tapCoordinates
                    if coordinates.latitude == 0 && coordinates.longitude == 0 {
                        print("coordinate not set")
                        return
                    }
                    let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    Task {
                        await RadarSDKIndoors.setLocation(location)
                    }
                }
                
                Button("get") {
                    Task {
                        let features: [String: MLFeatureValue] = [
                            "seplen": MLFeatureValue(double: 6.5),
                            "sepwid": MLFeatureValue(double: 3.0),
                            "petlen": MLFeatureValue(double: 5.2),
                            "petwid": MLFeatureValue(double: 2.0),
                        ]
                        let provider = try MLDictionaryFeatureProvider(dictionary: features)
                        print(provider)
                    }
                }
            }
            HStack(spacing: 20) {
                Button("init") {
                    RadarSDKIndoors.nothing()
                }
                
                Button("start") {
                    let locationManager = CLLocationManager()
                    locationManager.monitoredRegions.forEach {
                        locationManager.stopMonitoring(for: $0)
                    }
                    Task {
                        await RadarSDKIndoors.start()
                    }
                }
                
                Button("stop") {
                    Task {
                        await RadarSDKIndoors.stop()
                    }
                }
            }
            Spacer()
        }
    }
}

#Preview {
    DebugView()
}
