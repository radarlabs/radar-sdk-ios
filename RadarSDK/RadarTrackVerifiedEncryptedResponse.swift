//
//  RadarTrackVerifiedEncryptedResponse.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/11/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// An encrypted trackVerified response to relay to the customer backend.
@objc(RadarTrackVerifiedEncryptedResponse)
@objcMembers
public final class RadarTrackVerifiedEncryptedResponse: NSObject {
    /// The Radar ID of the location check.
    public let _id: String
    
    /// The opaque token that the customer backend decrypts and verifies.
    public let token: String
    
    /// The datetime when the token expires.
    public let expiresAt: Date
    
    /// The number of seconds until the token expires.
    public let expiresIn: TimeInterval
    
    /// An optional refresh hint. Authorization decisions require backend verification.
    public let passed: NSNumber?
    
    /// The optional distance to the state border, in meters.
    public let distanceToBorder: NSNumber?
    
    @nonobjc
    init(
        id: String,
        token: String,
        expiresAt: Date,
        expiresIn: TimeInterval,
        passed: Bool?,
        distanceToBorder: Double?
    ) {
        self._id = id
        self.token = token
        self.expiresAt = expiresAt
        self.expiresIn = expiresIn
        self.passed = passed.map { NSNumber(value: $0) }
        self.distanceToBorder = distanceToBorder.map { NSNumber(value: $0) }
        super.init()
    }
}
