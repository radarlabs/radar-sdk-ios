//
//  FormatCheckSample.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// Sample file for testing CI's swift-format check. Not part of the SDK; do not merge.

import Foundation

enum FormatCheckSample{
  static func describe( _ values:[Int] )->String{
        values.map{String($0)}.joined(separator:", ")
  }
}
