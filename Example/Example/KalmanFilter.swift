//
//  KalmanFilter.swift
//  Example
//
//  Created by ShiCheng Lu on 11/25/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import simd

class KalmanFilter {
    var x = simd_double2(0, 0)
    var P = matrix_identity_double2x2 * 1000
    
    var Q = matrix_identity_double2x2 * 1.3 // process covariance (walking speed)
    var R = matrix_identity_double2x2 * 25 //
    
    func predict() -> simd_double2 {
        P = P + Q
        return x
    }
    
    func update(z: simd_double2) {
        let y = z - x
        let S = P + R
        let K = P * S.inverse
        x = x + K * y
        P = (matrix_identity_double2x2 - K) * P
    }
    
    func dom_eigval() -> Double {
        let a = P[0][0]
        let b = P[0][1]
        let c = P[1][0]
        let d = P[1][1]
        
        let det = a*d - b*c
        let tr = a+d
        
        let l1 = (tr + sqrt(tr*tr - 4*det))/2
        let l2 = (tr - sqrt(tr*tr - 4*det))/2
        
        return abs(l1) > abs(l2) ? l1 : l2
    }
    
    func error_radius() -> Double {
        let k = 0.103 // Chi2 df=2, p=0.95
        return k * sqrt(dom_eigval())
    }
}
