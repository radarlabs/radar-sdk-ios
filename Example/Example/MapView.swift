//
//  MapView.swift
//  Example
//
//  Created by Greg Sadetsky on 2/7/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapLibre

class MapViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    weak var mapCoordinator: MapView.Coordinator?  // Add this to store coordinator reference
    var confidenceLabel: UILabel?  // Add this
    var tappedGeofencesTableView: UITableView?
    var tappedGeofences: [(String, String)] = [] // [(id, description)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapHostingController = UIHostingController(rootView: MapView(
            fetchGeofences: appDelegate.fetchAllGeofences,
            onGeofenceTap: { id, description, completion in
                // Your existing tap handler function with completion
                self.appDelegate.didTapGeofenceButton(id, description) {
                    completion()
                }
            },
            onMultipleGeofencesTap: { [weak self] geofences in
                // Update the table view with the tapped geofences
                self?.updateTappedGeofences(geofences)
            },
            onCoordinatorCreated: { [weak self] coordinator in  // Add this callback
                self?.mapCoordinator = coordinator
            }
        ))
        
        // Add a label for confidence
        let confidenceLabel = UILabel()
        confidenceLabel.textAlignment = .center
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        self.confidenceLabel = confidenceLabel

        addChild(mapHostingController)
        view.addSubview(mapHostingController.view)
        view.addSubview(confidenceLabel)

        let tappedGeofencesTableView = UITableView()
        tappedGeofencesTableView.register(GeofenceTableViewCell.self, forCellReuseIdentifier: "GeofenceCell")

        tappedGeofencesTableView.translatesAutoresizingMaskIntoConstraints = false
        tappedGeofencesTableView.delegate = self
        tappedGeofencesTableView.dataSource = self
        tappedGeofencesTableView.isHidden = true // Initially hidden
        tappedGeofencesTableView.allowsSelection = false
        
        tappedGeofencesTableView.layer.borderWidth = 1
        tappedGeofencesTableView.layer.borderColor = UIColor.red.cgColor
        tappedGeofencesTableView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)

        self.tappedGeofencesTableView = tappedGeofencesTableView

        view.addSubview(tappedGeofencesTableView)

        NSLayoutConstraint.activate([
            // Additional constraints for the table view
            tappedGeofencesTableView.topAnchor.constraint(equalTo: confidenceLabel.bottomAnchor, constant: 5),
            tappedGeofencesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tappedGeofencesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tappedGeofencesTableView.heightAnchor.constraint(equalToConstant: 120) // Adjust height as needed
        ])
        
        mapHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mapHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapHostingController.view.heightAnchor.constraint(equalToConstant: 400),

            confidenceLabel.topAnchor.constraint(equalTo: mapHostingController.view.bottomAnchor, constant: 0), // changed from 10 to 30
            confidenceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confidenceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confidenceLabel.heightAnchor.constraint(equalToConstant: 10)
        ])
        mapHostingController.didMove(toParent: self)
}

    func handlePrediction(geofenceId: String, confidence: Double) {
        print("Handling prediction", geofenceId, confidence)
        if let coordinator = mapCoordinator {
            print("calling coordinator.updateHighlight")
            coordinator.updateHighlight(geofenceId: geofenceId)

            print("confidenceLabel", confidenceLabel)
            confidenceLabel?.text = String(format: "Confidence: %.1f%%", confidence * 100)
        } else {
            print("Coordinator not found!!!!!!!!!!!!")
        }
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tappedGeofences.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GeofenceCell", for: indexPath) as? GeofenceTableViewCell else {
            print("Failed to dequeue GeofenceTableViewCell")
            return UITableViewCell()
        }
        
        let geofence = tappedGeofences[indexPath.row]
        
        // Configure the cell with geofence data and button action
        cell.configure(id: geofence.0, description: geofence.1) { [weak self] geofenceId, geofenceDescription in
            print("Survey button action triggered for: \(geofenceId)")
            
            self?.disableAllSurveyButtons()

            // Show processing state
            cell.surveyButton.isEnabled = false
            cell.surveyButton.alpha = 0.7
            cell.surveyButton.setTitle("...", for: .disabled)
            
            print("ABOUT TO SURVEY ABOUT TO SURVEY")
            
            // Trigger survey for this geofence - pass the button reference
            self?.appDelegate.didTapGeofenceButton(geofenceId, geofenceDescription, button: cell.surveyButton) {
                
                self?.enableAllSurveyButtons()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let geofence = tappedGeofences[indexPath.row]
        
        // Start survey for the selected geofence
        appDelegate.didTapGeofenceButton(geofence.0, geofence.1) {
            print("Survey completed for selected geofence")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44 // Standard cell height
    }
    
    func updateTappedGeofences(_ geofences: [(String, String)]) {
        let sortedGeofences = geofences.sorted { $0.1 < $1.1 }
        tappedGeofences = sortedGeofences
        tappedGeofencesTableView?.reloadData()
        tappedGeofencesTableView?.isHidden = geofences.isEmpty
    }
    
    func disableAllSurveyButtons() {
        for cell in tappedGeofencesTableView?.visibleCells ?? [] {
            if let geofenceCell = cell as? GeofenceTableViewCell {
                geofenceCell.surveyButton.isEnabled = false
                geofenceCell.surveyButton.alpha = 0.7
                geofenceCell.surveyButton.setTitle("...", for: .disabled)
            }
        }
    }

    func enableAllSurveyButtons() {
        for cell in tappedGeofencesTableView?.visibleCells ?? [] {
            if let geofenceCell = cell as? GeofenceTableViewCell {
                geofenceCell.surveyButton.isEnabled = true
                geofenceCell.surveyButton.alpha = 1.0
                geofenceCell.surveyButton.setTitle("Survey", for: .normal)
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    let fetchGeofences: (@escaping ([(String, String, [[CLLocationCoordinate2D]], String)]) -> Void) -> Void
    let onGeofenceTap: (String, String, @escaping () -> Void) -> Void  // Updated with completion
    let onCoordinatorCreated: (Coordinator) -> Void  // Add this
    let onMultipleGeofencesTap: ([(String, String)]) -> Void

    init(
        fetchGeofences: @escaping (@escaping ([(String, String, [[CLLocationCoordinate2D]], String)]) -> Void) -> Void,
        onGeofenceTap: @escaping (String, String, @escaping () -> Void) -> Void,
        onMultipleGeofencesTap: @escaping ([(String, String)]) -> Void,
        onCoordinatorCreated: @escaping (Coordinator) -> Void
    ) {
        self.fetchGeofences = fetchGeofences
        self.onGeofenceTap = onGeofenceTap
        self.onMultipleGeofencesTap = onMultipleGeofencesTap
        self.onCoordinatorCreated = onCoordinatorCreated
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        onCoordinatorCreated(coordinator)  // Store reference when coordinator is created
        return coordinator
    }

    func makeUIView(context: Context) -> MLNMapView {
        // create a map

        let style = "radar-default-v1"
        let publishableKey = "prj_test_pk_2e4715e49b97eb6b09e4f1035068548ccfeeb683"
        let styleURL = URL(string: "https://api.radar.io/maps/styles/\(style)?publishableKey=\(publishableKey)")

        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.logoView.isHidden = true
        mapView.showsUserLocation = true
        
        mapView.gestureRecognizers?.forEach { gesture in
            if gesture is UITapGestureRecognizer,
               let tapGesture = gesture as? UITapGestureRecognizer,
               tapGesture.numberOfTapsRequired == 2 {
                tapGesture.isEnabled = false
            }
        }

        mapView.setCenter(
          CLLocationCoordinate2D(latitude: 40.69528687406046, longitude: -74.1769155204496),
          zoomLevel: 12,
          animated: false
        )
        
        mapView.delegate = context.coordinator

        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {

    }
    
    // add a marker on map load

    class Coordinator: NSObject, MLNMapViewDelegate {
        var mapView: MLNMapView?
        var geofenceIdToLayer: [String: (MLNFillStyleLayer, MLNLineStyleLayer)] = [:]
        var control: MapView
        var isProcessing = false
        var statusLabel: UILabel?  // Move the label here
        var geofenceDetails: [String: (String, String)] = [:] // [id: (description, tag)]

        init(_ control: MapView) {
            self.control = control
        }

        func setupStatusLabel(in mapView: MLNMapView) {
            let label = UILabel()
            label.textAlignment = .center
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.textColor = .white
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.isHidden = true
            label.text = "Surveying..."
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            mapView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -20),
                label.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
                label.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            self.statusLabel = label
        }
        
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            self.mapView = mapView
            setupStatusLabel(in: mapView)  // Setup the label when map loads
            
            // Add tap recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
            mapView.addGestureRecognizer(tapGesture)

            // Fetch and add geofences once the map style is loaded
            control.fetchGeofences { geofences in
               DispatchQueue.main.async {
                   self.addGeofences(to: style, geofences: geofences)
               }
           }
       }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard !isProcessing, let mapView = self.mapView else { return }
            
            let point = gesture.location(in: mapView)
            
            // Get all layers that might be at this point
            let allFeatures = mapView.visibleFeatures(
                at: point,
                styleLayerIdentifiers: Set(geofenceIdToLayer.keys.map { "geofence-fill-\($0)" })
            )
            
            // Filter to polygon features only
            let polygonFeatures = allFeatures.compactMap { $0 as? MLNPolygonFeature }
            
            if polygonFeatures.count > 0 {
                // Get geofence IDs and descriptions
                var tappedGeofences: [(String, String)] = []
                
                for feature in polygonFeatures {
                    if let geofenceId = feature.identifier as? String, let details = geofenceDetails[geofenceId] {
                        // Find the description from our geofence data
                        // For now using a placeholder - you need to update this to get real descriptions
                        let geofenceDescription = details.0 // Get the actual description
                        tappedGeofences.append((geofenceId, geofenceDescription))
                    }
                }
                
                control.onMultipleGeofencesTap(tappedGeofences)
            }
        }

        func updateHighlight(geofenceId: String?) {
            // Reset all geofences to original style
            for (id, (fillLayer, strokeLayer)) in geofenceIdToLayer {
                let (fillColor, strokeColor, fillOpacity, strokeWidth) = styleForTag(id)
                fillLayer.fillColor = NSExpression(forConstantValue: fillColor.withAlphaComponent(fillOpacity))
                strokeLayer.lineColor = NSExpression(forConstantValue: strokeColor)
                strokeLayer.lineWidth = NSExpression(forConstantValue: strokeWidth)
            }
            
            // Highlight selected geofence
            if let id = geofenceId, let (fillLayer, strokeLayer) = geofenceIdToLayer[id] {
                fillLayer.fillColor = NSExpression(forConstantValue: UIColor.red.withAlphaComponent(0.5))
                strokeLayer.lineColor = NSExpression(forConstantValue: UIColor.red)
                strokeLayer.lineWidth = NSExpression(forConstantValue: 3.0)
            }
        }

        func addGeofences(to style: MLNStyle, geofences: [(String, String, [[CLLocationCoordinate2D]], String)]) {
            for (id, description, coordinates, tag) in geofences {
                // Store geofence details
                geofenceDetails[id] = (description, tag)

                let outerRing = coordinates[0]
                
                // let polygon = MLNPolygon(coordinates: outerRing, count: UInt(outerRing.count))
                let feature = MLNPolygonFeature(coordinates: outerRing, count: UInt(outerRing.count))
                feature.identifier = id  // Set the id directly on the feature
                
                let shapeSource = MLNShapeSource(identifier: "geofence-source-\(id)", shape: feature, options: nil)
                
                let fillLayer = MLNFillStyleLayer(identifier: "geofence-fill-\(id)", source: shapeSource)
                let strokeLayer = MLNLineStyleLayer(identifier: "geofence-stroke-\(id)", source: shapeSource)
                
                let (fillColor, strokeColor, fillOpacity, strokeWidth) = styleForTag(tag)
                
                fillLayer.fillColor = NSExpression(forConstantValue: fillColor.withAlphaComponent(fillOpacity))
                strokeLayer.lineColor = NSExpression(forConstantValue: strokeColor)
                strokeLayer.lineWidth = NSExpression(forConstantValue: strokeWidth)
                
                style.addSource(shapeSource)
                style.addLayer(fillLayer)
                style.addLayer(strokeLayer)
                
                geofenceIdToLayer[id] = (fillLayer, strokeLayer)
            }
        }
        
        private func styleForTag(_ tag: String) -> (UIColor, UIColor, CGFloat, CGFloat) {
            switch tag {
            case "airport":
                return (UIColor.gray, UIColor.darkGray, 0.1, 2.0)
            case "lga":
                return (UIColor.blue, UIColor.blue, 0.2, 1.5)
            case "lga-gates":
                return (UIColor.green, UIColor.green, 0.3, 1.0)
            default: // geofenceoffice tags
                return (UIColor.purple, UIColor.purple, 0.2, 1.0)
            }
        }

    }
}

class GeofenceTableViewCell: UITableViewCell {
    var surveyButton: UIButton!
    var geofenceId: String?
    var geofenceDescription: String?
    var onSurveyButtonTap: ((String, String) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        // Create survey button
        surveyButton = UIButton(type: .system)
        surveyButton.setTitle("Survey", for: .normal)
        surveyButton.backgroundColor = .systemBlue
        surveyButton.setTitleColor(.white, for: .normal)
        surveyButton.layer.cornerRadius = 5
        surveyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure text label doesn't overlap with button
        textLabel?.translatesAutoresizingMaskIntoConstraints = true
        
        // Add button to cell
        contentView.addSubview(surveyButton)
        
        // Configure constraints to ensure button is accessible
        NSLayoutConstraint.activate([
            surveyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            surveyButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            surveyButton.widthAnchor.constraint(equalToConstant: 70),
            surveyButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Make sure the text label doesn't overlap with the button
        if let textLabel = textLabel {
            textLabel.frame.size.width = contentView.frame.width - 100 // Leave space for button
        }
        
        surveyButton.addTarget(self, action: #selector(surveyButtonTapped), for: .touchUpInside)
    }
    
    // Then add this method to the GeofenceTableViewCell class:
    @objc private func surveyButtonTapped() {
        print("Survey button tapped via target-action")
        guard let id = self.geofenceId,
              let description = self.geofenceDescription else {
            print("Missing geofence data in cell")
            return
        }
        print("Calling onSurveyButtonTap with \(id), \(description)")
        self.onSurveyButtonTap?(id, description)
    }
    
    func configure(id: String, description: String, action: @escaping (String, String) -> Void) {
        self.geofenceId = id
        self.geofenceDescription = description
        self.onSurveyButtonTap = action
        self.textLabel?.text = description
    }
}

