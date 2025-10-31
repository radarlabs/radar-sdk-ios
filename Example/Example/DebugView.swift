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
import MapLibreSwiftUI
import MapLibreSwiftDSL
import MapLibre


extension MapView where T == MLNMapViewController {
    init(withRadar publishableKey: String) {
        let style = "radar-default-v1"
        let styleURL = URL(string: "https://api.radar.io/maps/styles/\(style)?publishableKey=\(publishableKey)")!
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["X-Radar-Mobile-Origin": Bundle.main.bundleIdentifier ?? ""]
        sessionConfig.httpAdditionalHeaders?["Authorization"] = publishableKey
        MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
        
        self.init(styleURL: styleURL)
    }
}

struct DebugView: View {
    
    @State
    var tapCoordinates = CLLocationCoordinate2D()
    
    @State
    var image: UIImage? = nil
    
    let site: RadarSite? = {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let siteResponse = try decoder.decode(RadarSiteResponse.self, from: Data(siteString.utf8))
            return siteResponse.site
        } catch {
            return nil
        }
    }()
    
    var body: some View {
        VStack(spacing: 10) {
            MyMapView(withRadar: "prj_test_pk_3508428416f485c5f54d8e8bb1f616ee405b1995")
                .onStyleLoaded { style in
                    guard let site else {
                        return
                    }
                    let coords = site.floorplan.geometry.coordinates
                    let coordinates = Quad(
                        coords[0][0].reversed(),
                        coords[0][3].reversed(),
                        coords[0][2].reversed(),
                        coords[0][1].reversed(),
                    )
                    let imageSource = MLNImageSource(
                        identifier: "overlay‑src",
                        coordinateQuad: coordinates,
                        url: URL(string: "https://api-shicheng.radar-staging.com/api/v1/assets/\(site.floorplan.path)")!
                    )
                    style.addSource(imageSource)
                    let rasterLayer = MLNRasterStyleLayer(identifier: "overlay‑layer", source: imageSource)
                    style.addLayer(rasterLayer)
                    
                    let pointsSource = MLNShapeSource(identifier: "points-src", shape: MLNPointFeature(coordinate: tapCoordinates))
                    style.addSource(pointsSource)
                    let pointsLayer = MLNCircleStyleLayer(identifier: "points-layer", source: pointsSource)
                    pointsLayer.circleRadius = NSExpression(forConstantValue: 5)
                    pointsLayer.circleColor = NSExpression(forConstantValue: UIColor.red)
                    style.addLayer(pointsLayer)
                }
                .onTapMapGesture { value in
                    tapCoordinates = value.coordinate
                    if let source = value.mapView.style?.source(withIdentifier: "points-src"),
                       let pointSource = source as? MLNShapeSource {
                        pointSource.shape = MLNPointFeature(coordinate: value.coordinate)
                    }
                }
            
//            MapView(styleURL: styleURL).onStyleLoaded { style in
//                
//            }
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
                        await RadarSDKIndoors.getLocation()
                    }
                }
                
                Button("site") {
                    Task {
                        do {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            
//                            let encoder = JSONEncoder()
//                            encoder.dateEncodingStrategy = .formatted(dateFormatter)
//                            
//                            let x = try encoder.encode(GeoJSONGeometry.point([1, 2]))
//                            print(String(data: x, encoding: .utf8))
//                            
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .formatted(dateFormatter)
                            
                            let y = try decoder.decode(RadarSiteResponse.self, from: Data(siteString.utf8))
                            print(y)
                        } catch {
                            print(error)
                        }
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
