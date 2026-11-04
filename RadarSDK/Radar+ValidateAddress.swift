//
//  Radar+ValidateAddress.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

extension Radar {

    /// Validates an address from its street and number, attaching a verification status, property type, and ZIP+4.
    ///
    /// Every field except `unit` is required. If one is empty, the completion handler is called with
    /// `RadarStatus.errorBadRequest` and no request is sent.
    ///
    /// - Parameters:
    ///   - street: The street name, such as `"Jay St"`.
    ///   - number: The street number, such as `"20"`.
    ///   - unit: The unit, such as an apartment or suite number.
    ///   - city: The city.
    ///   - stateCode: The state code, such as `"NY"`.
    ///   - postalCode: The postal code.
    ///   - countryCode: The two-letter country code, such as `"US"`.
    ///   - completionHandler: A completion handler, called on the main thread.
    ///
    /// - SeeAlso: https://radar.com/documentation/api#validate-an-address
    @objc public static func validateAddress(  // swiftlint:disable:this function_parameter_count
        street: String,
        number: String,
        unit: String? = nil,
        city: String,
        stateCode: String,
        postalCode: String,
        countryCode: String,
        completionHandler: @escaping @Sendable (RadarStatus, RadarAddress?, RadarAddressVerificationStatus) -> Void
    ) {
        RadarLogger.shared.info("validateAddress()", type: .sdkCall)
        validateAddress(
            RadarValidateAddressRequest(
                line: .streetAndNumber(street: street, number: number),
                unit: unit,
                city: city,
                stateCode: stateCode,
                postalCode: postalCode,
                countryCode: countryCode
            ),
            completionHandler: completionHandler
        )
    }

    /// Validates an address from a single-line address label, attaching a verification status, property type, and
    /// ZIP+4.
    ///
    /// Every field except `unit` is required. If one is empty, the completion handler is called with
    /// `RadarStatus.errorBadRequest` and no request is sent.
    ///
    /// - Parameters:
    ///   - addressLabel: The street address on one line, such as `"20 Jay St"`.
    ///   - unit: The unit, such as an apartment or suite number.
    ///   - city: The city.
    ///   - stateCode: The state code, such as `"NY"`.
    ///   - postalCode: The postal code.
    ///   - countryCode: The two-letter country code, such as `"US"`.
    ///   - completionHandler: A completion handler, called on the main thread.
    ///
    /// - SeeAlso: https://radar.com/documentation/api#validate-an-address
    @objc public static func validateAddress(  // swiftlint:disable:this function_parameter_count
        addressLabel: String,
        unit: String? = nil,
        city: String,
        stateCode: String,
        postalCode: String,
        countryCode: String,
        completionHandler: @escaping @Sendable (RadarStatus, RadarAddress?, RadarAddressVerificationStatus) -> Void
    ) {
        RadarLogger.shared.info("validateAddress()", type: .sdkCall)
        validateAddress(
            RadarValidateAddressRequest(
                line: .label(addressLabel),
                unit: unit,
                city: city,
                stateCode: stateCode,
                postalCode: postalCode,
                countryCode: countryCode
            ),
            completionHandler: completionHandler
        )
    }

    // Backs the deprecated `validateAddress(address:)`, declared in Radar+Internal.h.
    @objc(validateRadarAddress:completionHandler:)
    static func validate(
        _ address: RadarAddress,
        completionHandler: @escaping @Sendable (RadarStatus, RadarAddress?, RadarAddressVerificationStatus) -> Void
    ) {
        RadarLogger.shared.info("validateAddress()", type: .sdkCall)
        validateAddress(RadarValidateAddressRequest(address: address), completionHandler: completionHandler)
    }

    static func validateAddress(
        _ request: RadarValidateAddressRequest,
        apiClient: RadarAPIClient = .shared,
        completionHandler: @escaping @Sendable (RadarStatus, RadarAddress?, RadarAddressVerificationStatus) -> Void
    ) {
        Task { @MainActor in
            do {
                let response = try await apiClient.validateAddress(request)
                completionHandler(.success, response.address, response.verificationStatus)
            } catch let error as RadarError {
                RadarLogger.shared.error("validateAddress() failed: \(error.message ?? Radar.stringForStatus(error.status))")
                completionHandler(error.status, nil, .none)
            } catch is URLError {
                completionHandler(.errorNetwork, nil, .none)
            } catch {
                RadarLogger.shared.error("validateAddress() failed: \(error)")
                completionHandler(.errorServer, nil, .none)
            }
        }
    }
}
