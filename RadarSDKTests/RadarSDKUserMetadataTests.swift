//
//  RadarSDKUserMetadataTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    @MainActor
    struct RadarSDKUserMetadataTests {
        private let fixture = RadarSDKTestFixture()

        private let altitudeAdjustments: [[String: Any]] = [
            ["geofenceId": "abc123", "altitude": 100.5, "confidence": 3],
            ["geofenceId": "def456", "altitude": 200.0, "confidence": 2],
        ]

        /// Tracks once with a mocked location and `response`, and returns the status.
        private func trackOnce(response: [AnyHashable: Any]) async -> RadarStatus {
            fixture.permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            fixture.locationManagerMock.mockLocation = RadarSDKTestResources.manhattanLocation()
            fixture.apiHelperMock.mockStatus = .success
            fixture.apiHelperMock.mockResponse = response

            return await awaitCompletion { resume in
                Radar.trackOnce { status, _, _, _ in
                    resume(status)
                }
            }
        }

        @Test("initialize stores the publishable key")
        func initialize() {
            #expect(RadarSettings.publishableKey == RadarSDKTestResources.publishableKey)
            #expect(Radar.isInitialized)
        }

        @Test("setUserId stores the user ID")
        func setUserId() {
            Radar.setUserId("userId")
            #expect(Radar.getUserId() == "userId")
        }

        @Test("setUserId(nil) clears the user ID")
        func setUserIdNil() {
            Radar.setUserId(nil)
            #expect(Radar.getUserId() == nil)
        }

        @Test("setDescription stores the description")
        func setDescription() {
            Radar.setDescription("description")
            #expect(Radar.getDescription() == "description")
        }

        @Test("setDescription(nil) clears the description")
        func setDescriptionNil() {
            Radar.setDescription(nil)
            #expect(Radar.getDescription() == nil)
        }

        @Test("setMetadata stores the metadata")
        func setMetadata() {
            let metadata: [String: Any] = ["foo": "bar", "baz": true, "qux": 1]
            Radar.setMetadata(metadata)
            #expect(Radar.getMetadata().map { NSDictionary(dictionary: $0) } == NSDictionary(dictionary: metadata))
        }

        @Test("setMetadata(nil) clears the metadata")
        func setMetadataNil() {
            Radar.setMetadata(nil)
            #expect(Radar.getMetadata() == nil)
        }

        @Test("addTags adds to the existing tags")
        func addUserTags() {
            Radar.addTags(["tag1", "tag2"])
            Radar.addTags(["tag3", "tag4"])
            #expect(Radar.getTags()?.sorted() == ["tag1", "tag2", "tag3", "tag4"])
        }

        @Test("addTags ignores duplicate tags")
        func addUserTagsDuplicate() {
            Radar.addTags(["tag1", "tag2"])
            Radar.addTags(["tag2", "tag3"])
            #expect(Radar.getTags()?.sorted() == ["tag1", "tag2", "tag3"])
        }

        @Test("removeTags removes only the given tags")
        func removeUserTags() {
            Radar.addTags(["tag1", "tag2", "tag3", "tag4"])
            Radar.removeTags(["tag2", "tag4"])
            #expect(Radar.getTags()?.sorted() == ["tag1", "tag3"])
        }

        @Test("removeTags ignores tags that aren't set")
        func removeUserTagsNonexistent() {
            Radar.addTags(["tag1", "tag2"])
            Radar.removeTags(["tag3", "tag4"])
            #expect(Radar.getTags()?.sorted() == ["tag1", "tag2"])
        }

        @Test("removeTags can remove every tag")
        func removeUserTagsAll() {
            Radar.addTags(["tag1", "tag2"])
            Radar.removeTags(["tag1", "tag2"])
            #expect((Radar.getTags() ?? []).isEmpty)
        }

        @Test("setTags stores the tags")
        func setUserTags() {
            Radar.setTags(["tag1", "tag2", "tag3"])
            #expect(Radar.getTags()?.sorted() == ["tag1", "tag2", "tag3"])
        }

        @Test("setTags(nil) clears the tags")
        func setUserTagsNil() {
            Radar.addTags(["tag1", "tag2"])
            Radar.setTags(nil)
            #expect((Radar.getTags() ?? []).isEmpty)
        }

        @Test("setTags replaces the existing tags")
        func setUserTagsReplacesExisting() {
            Radar.addTags(["tag1", "tag2", "tag3"])
            Radar.setTags(["newTag1", "newTag2"])

            let tags = Radar.getTags() ?? []
            #expect(tags.sorted() == ["newTag1", "newTag2"])
            #expect(!tags.contains("tag1"))
            #expect(!tags.contains("tag2"))
            #expect(!tags.contains("tag3"))
        }

        @Test("trackOnce sends the user tags")
        func userTagsIncludedInTrackAPI() async throws {
            let userTags = ["premium_user", "beta_tester", "location_enabled"]
            Radar.addTags(userTags)

            let status = await trackOnce(response: try RadarSDKTestResources.jsonDictionary(fromResource: "track"))

            #expect(status == .success)
            let params = try #require(fixture.apiHelperMock.lastParams)
            #expect(fixture.apiHelperMock.lastMethod == "POST")
            #expect(fixture.apiHelperMock.lastUrl?.contains("/v1/track") == true)
            let apiUserTags = try #require(params["userTags"] as? [String])
            #expect(apiUserTags.sorted() == userTags.sorted())
        }

        @Test("trackOnce stores the altitude adjustments from the response")
        func altitudeAdjustmentsStoredFromTrackResponse() async throws {
            var response = try RadarSDKTestResources.jsonDictionary(fromResource: "track")
            var user = try #require(response["user"] as? [AnyHashable: Any])
            user["altitudeAdjustments"] = altitudeAdjustments
            response["user"] = user

            let status = await trackOnce(response: response)

            #expect(status == .success)
            let stored = try #require(RadarState.shared.altitudeAdjustments)
            #expect(stored.count == 2)
            #expect(stored[0]["geofenceId"] as? String == "abc123")
            #expect(stored[0]["altitude"] as? Double == 100.5)
            #expect(stored[1]["geofenceId"] as? String == "def456")
            #expect(stored[1]["altitude"] as? Double == 200.0)
        }

        @Test("trackOnce sends the stored altitude adjustments")
        func altitudeAdjustmentsIncludedInTrackRequest() async throws {
            RadarState.shared.altitudeAdjustments = altitudeAdjustments

            let status = await trackOnce(response: try RadarSDKTestResources.jsonDictionary(fromResource: "track"))

            #expect(status == .success)
            #expect(fixture.apiHelperMock.lastUrl?.contains("/v1/track") == true)
            let params = try #require(fixture.apiHelperMock.lastParams)
            let apiAdjustments = try #require(params["altitudeAdjustments"] as? [[String: Any]])
            #expect(apiAdjustments.count == 2)
            #expect(apiAdjustments[0]["geofenceId"] as? String == "abc123")
            #expect(apiAdjustments[1]["geofenceId"] as? String == "def456")
        }

        @Test("altitude adjustments persist in RadarState until cleared")
        func altitudeAdjustmentsPersistAcrossSessions() throws {
            RadarState.shared.altitudeAdjustments = altitudeAdjustments

            let stored = try #require(RadarState.shared.altitudeAdjustments)
            #expect(stored.count == 2)
            #expect(stored[0]["geofenceId"] as? String == "abc123")
            #expect(stored[0]["altitude"] as? Double == 100.5)
            #expect(stored[0]["confidence"] as? Int == 3)
            #expect(stored[1]["geofenceId"] as? String == "def456")
            #expect(stored[1]["altitude"] as? Double == 200.0)
            #expect(stored[1]["confidence"] as? Int == 2)

            RadarState.shared.altitudeAdjustments = nil
            #expect(RadarState.shared.altitudeAdjustments == nil)
        }

        @Test("trackOnce clears altitude adjustments missing from the response")
        func altitudeAdjustmentsClearedWhenNotInTrackResponse() async throws {
            RadarState.shared.altitudeAdjustments = [["geofenceId": "stale", "altitude": 50.0]]
            #expect(RadarState.shared.altitudeAdjustments != nil)

            let status = await trackOnce(response: try RadarSDKTestResources.jsonDictionary(fromResource: "track"))

            #expect(status == .success)
            #expect(RadarState.shared.altitudeAdjustments == nil)
        }
    }
}
