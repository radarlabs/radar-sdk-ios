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
    
    @State
    var holding = false
    
    @State
    var success = false
    
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
                    let coordinates = MLNCoordinateQuad(
                        topLeft:     CLLocationCoordinate2D(latitude: coords[0][0][1], longitude: coords[0][0][0]),
                        bottomLeft:  CLLocationCoordinate2D(latitude: coords[0][3][1], longitude: coords[0][3][0]),
                        bottomRight: CLLocationCoordinate2D(latitude: coords[0][2][1], longitude: coords[0][2][0]),
                        topRight:    CLLocationCoordinate2D(latitude: coords[0][1][1], longitude: coords[0][1][0]),
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
            
            HStack(spacing: 20) {
                Circle()
                    .fill((success && holding) ? Color.green : Color.gray)
                    .frame(width: 20, height: 20)
                
                Button(action: {
                    holding = false
                    success = false
                    
                    print("Stopped survey")
                    RadarSDKIndoors.onRangedBeacon {}
                }) {
                    Text("Survey")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100) // Set a large size
                        .background(Color.red)
                        .clipShape(Circle()) // Make it round
                }.simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.1).onChanged { _ in
                        holding = true
                        // set it up so that every time beacon is ranged, we send up the data (if we are holding the button)
                        print("Started survey")
                        RadarSDKIndoors.onRangedBeacon {
                            let coordinates = tapCoordinates
                            if coordinates.latitude == 0 && coordinates.longitude == 0 {
                                return
                            }
                            let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                            Task {
                                success = await RadarSDKIndoors.setLocation(location)
                            }
                        }
                    }
                )
            }.onAppear {
                RadarSDKIndoors.nothing()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Task {
                        await RadarSDKIndoors.start()
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
