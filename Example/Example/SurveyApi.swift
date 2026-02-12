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
    var rssi: [String: Int]
}

extension NSMutableData {
  func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}

struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func addTextField(named name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    func addDataField(named name: String, data: Data, mimeType: String) {
        httpBody.append(dataFormField(named: name, data: data, mimeType: mimeType))
    }

    private func dataFormField(named name: String,
                               data: Data,
                               mimeType: String) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }
    
    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        httpBody.append("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
}


extension URLSession {
    func dataTask(with request: MultipartFormDataRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
    -> URLSessionDataTask {
        return dataTask(with: request.asURLRequest(), completionHandler: completionHandler)
    }
}


class SurveyApi {
    static func createSurvey(data: Data) async {
        let suite = UserDefaults.standard.string(forKey: "radar-appGroup")
        
        let radarHost = UserDefaults(suiteName: suite)?.string(forKey: "radar-host") ?? "https://api.radar-staging.com"
        let publishableKey = UserDefaults(suiteName: suite)?.string(forKey: "radar-publishableKey") ?? ""
        let description = "ORD survey"
        let geofenceId = "698cfb5b8b6de165a76b0c9a"
        let surveyor = "Arek"
        
        // create the survey record on server
        var uploadUrl: String? = nil
        var surveyId: String? = nil
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
                "geofenceId": geofenceId,
                "surveyor": surveyor
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            // send the request
            let (data, _) = try await URLSession.shared.data(for: request)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return print("Failed to json serialize response")
            }
            print(json)
            uploadUrl = json["uploadUrl"] as? String
            surveyId = (json["indoorSurvey"] as? [String: Any])?["_id"] as? String
        } catch {
            print("SurveyService: Failed: \(error.localizedDescription)")
        }
        
        do {
            guard let surveyId else {
                print("SurveyService: no survey id")
                return
            }
            let urlString = "\(radarHost)/v1/assets/surveys/\(geofenceId)/\(surveyId)/upload"
            guard let url = URL(string: urlString) else {
                print("SurveyService: Invalid URL: \(urlString)")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(publishableKey, forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            print(data)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return print("Failed to json serialize response")
            }
            print(json)
        } catch {
            print("SurveyService: Error getting asset upload url")
        }
        
        // upload to s3 via presigned url
        do {
            guard let urlString = uploadUrl,
                  let url = URL(string: urlString) else {
                print("did no receive valid upload url: \(uploadUrl)")
                return
            }
            var request = MultipartFormDataRequest(url: url)
            request.addDataField(named: "file", data: data, mimeType: "application/octet-stream")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    // The upload failed due to a client-side error (e.g., network issue).
                    print("Upload error: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        // The upload was successful and the server returned a success status code.
                        print("Upload successful! Status code: \(httpResponse.statusCode)")
                        // Process 'data' if the server returned any response data.
                    } else {
                        // The upload completed, but the server returned an error status code.
                        print("Server error: Status code \(httpResponse.statusCode)")
                    }
                } else {
                    // An unexpected scenario, potentially a non-HTTP response.
                    print("Unexpected response type.")
                }
            }.resume()
        }
        
        // update status to completed
        do {
            guard let surveyId,
                  let url = URL(string: "\(radarHost)/v1/indoor/surveys/\(surveyId)") else {
                return
            }
            print("requesting update at \(url.absoluteURL)")
            var request = URLRequest(url: url)
            
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(publishableKey, forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "status": "completed"
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return print("failed to json serialize response")
            }
            print(json)
        } catch {
            print("SurveyService: Update failed: \(error.localizedDescription)")
        }
        
    }
}
