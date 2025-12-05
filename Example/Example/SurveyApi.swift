//
//  SurveyApi.swift
//  Example
//
//  Created by ShiCheng Lu on 12/4/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

// csv data:
// timestamp, x, y, rssi values...

struct SurveyData {
    var timestamp: String
    var x: Double
    var y: Double
    var rssi: [String: Double]
}

class SurveyApi {
    func createSurvey() async {
        let radarHost = "https://api.radar-staging.com"
        let publishableKey = "prj_test_pk_3508428416f485c5f54d8e8bb1f616ee405b1995"
        let description = "Office Survey 1"
        let geofenceId = "69331ab62e3b06c78468cf3c"
        let surveyor = "ShiCheng"
        
        // create the survey record on server
        do {
            let urlString = "\(radarHost)/v1/indoor/surveys"
            guard let url = URL(string: urlString) else {
                print("SurveyService: Invalid URL: \(urlString)")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(publishableKey, forHTTPHeaderField: "Authorization")
            
            
            let body = [
                "description": description,
                "geofence_id": geofenceId,
                "surveyor": surveyor
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            // send the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
        } catch {
            print("SurveyService: Failed to encode request body: \(error.localizedDescription)")
        }
        
        
        // upload to s3 via presigned url
        do {
            var request = URLRequest(url: URL(string: "https://example.com/presigned-url")!)
            
            request.httpMethod = "PUT"
            
            let data = Data() // the csv content
            URLSession.shared.uploadTask(with: request, from: data)
        }
    }
}
