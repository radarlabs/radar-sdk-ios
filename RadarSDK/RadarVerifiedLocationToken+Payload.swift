//
//  RadarVerifiedLocationToken+Payload.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

public extension RadarVerifiedLocationToken {
    /// The fields available for each response format.
    /// Tokens and IDs must be verified by the receiving backend.
    enum Payload {
        case jws(
            user: RadarUser,
            events: [RadarEvent],
            token: String,
            passed: Bool,
            failureReasons: [String],
            expiresAt: Date
        )
        case jwe(token: String, expiresAt: Date)
        case id(String)
    }
    
    /// A Swift-only view of the response.
    /// Returns nil when the model lacks the fields required by its format
    @nonobjc
    var payload: Payload? {
        switch format {
        case .jws:
            guard let user, let events, let token,
                  let failureReasons, let expiresAt
            else {
                return nil
            }
            
            return .jws(
                user: user,
                events: events,
                token: token,
                passed: passed,
                failureReasons: failureReasons,
                expiresAt: expiresAt
            )
            
        case .jwe:
            guard let token, let expiresAt else {
                return nil
            }
            return .jwe(token: token, expiresAt: expiresAt)
            
        case .id:
            guard let id = _id else {
                return nil
            }
            return .id(id)
        }
    }
}
