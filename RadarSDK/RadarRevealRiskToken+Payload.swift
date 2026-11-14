//
//  RadarRevealRiskToken+Payload.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

public extension RadarRevealRiskToken {
    /// The fields available for each response format.
    /// Tokens and IDs must be verified by the receiving backend.
    enum Payload {
        case jws(
            risk: RadarRevealRiskTokenRisk,
            network: RadarRevealRiskTokenNetwork,
            device: RadarRevealRiskTokenDevice,
            token: String?,
            expiresAt: Date?
        )
        case jwe(token: String, expiresAt: Date)
        case id(String)
    }
    
    /// A Swift-only view of the response.
    /// Returns nil when the model lacks the fields required by its format.
    @nonobjc
    var payload: Payload? {
        switch format {
        case .jws:
            guard let risk, let network, let device else {
                return nil
            }

            return .jws(
                risk: risk,
                network: network,
                device: device,
                token: token,
                expiresAt: expiresAt
            )

        case .jwe:
            guard let token, let expiresAt else {
                return nil
            }
            return .jwe(token: token, expiresAt: expiresAt)

        case .id:
            return .id(_id)
        }
    }
}
