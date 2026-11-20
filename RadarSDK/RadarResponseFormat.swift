//
//  RadarResponseFormat.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/11/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// the format of a trackVerified or Reveal Risk response.
@objc(RadarResponseFormat)
public enum RadarResponseFormat: Int {
    /// A legacy response with  readable result fields and an optional signed token.
    case jws = 0

    /// An encrypted token that the customer backend decrypts and verifies.
    case jwe = 1

    /// An evaluation identifier that the customer backend uses to retrieve the result.
    case id = 2

    /// An omitted discriminator identifies a legacy JWS response.
    init?(responseValue: Any?) {
        guard let responseValue else {
            self = .jws
            return
        }

        guard let value = responseValue as? String else {
            return nil
        }

        switch value {
        case "jws":
            self = .jws
        case "jwe":
            self = .jwe
        case "id":
            self = .id
        default:
            return nil
        }
    }
}
