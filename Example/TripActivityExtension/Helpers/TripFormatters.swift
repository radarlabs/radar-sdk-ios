//
//  TripFormatters.swift
//  Example
//
//  Created by Alan Charles on 12/9/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

enum TripFormatters {
    static func formatDuration(_ duration: Double?, compact: Bool = false) -> String {
        guard let duration = duration else { return "Unknown" }
        
        let minutes = Int(duration.rounded())
        
        if minutes < 1 {
            return "Arriving"
        } else if minutes == 1 {
            return compact ? "1 min" : "1 minute"
        } else {
            return compact ? "\(minutes) min" : "\(minutes) minutes"
        }
    }
    
    static func formatDistance(_ meters: Float) -> String {
        let miles = meters * 0.000621371
        if miles < 0.1 {
            return String(format: "%.0f ft", meters * 3.28084)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
    
    static func mapStatusToStep(_ status: String) -> Int {
        switch status {
        case "started": return 1
        case "in_progress": return 2
        case "approaching": return 3
        case "arrived", "completed", "expired", "canceled": return 4
        default: return 0
        }
    }
    
    static func statusMessage(for step: Int) -> String {
        switch step {
        case 0: return "Your trip status is unknown"
        case 1: return "Your order is confirmed"
        case 2: return "Your trip is in progress"
        case 3: return "Approaching your destination"
        case 4: return "You have arrived at your destination"
        default: return "Your trip status is unknown"
        }
    }
}
