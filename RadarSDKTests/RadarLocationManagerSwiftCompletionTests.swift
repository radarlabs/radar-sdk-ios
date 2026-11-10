//
//  RadarLocationManagerSwiftCompletionTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

/// Records the timeouts a `RadarLocationCompletionStore` schedules, so a test can fire them.
final class ManualTimeoutScheduler: @unchecked Sendable {
    private(set) var delays: [TimeInterval] = []
    private(set) var timeouts: [DispatchWorkItem] = []

    func schedule(_ delay: TimeInterval, _ timeout: DispatchWorkItem) {
        delays.append(delay)
        timeouts.append(timeout)
    }
}

/// Records the calls a completion handler gets.
final class CompletionRecorder: @unchecked Sendable {
    struct Call {
        let status: RadarStatus
        let location: CLLocation?
        let stopped: Bool
    }

    private(set) var calls: [Call] = []

    var handler: RadarLocationCompletionHandler {
        { [self] status, location, stopped in
            calls.append(Call(status: status, location: location, stopped: stopped))
        }
    }
}

private typealias ObjCCompletionBlock = @convention(block) (RadarStatus, CLLocation?, Bool) -> Void
private typealias ObjCAddCompletionHandler = @convention(c) (AnyObject, Selector, ObjCCompletionBlock?) -> Void
private typealias ObjCCompletionHandlerCount = @convention(c) (AnyObject, Selector) -> Int
private typealias ObjCCallCompletionHandlers = @convention(c) (AnyObject, Selector, RadarStatus, CLLocation?) -> Void

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarLocationCompletionStoreTests {

        private func makeStore(
            stopped: Bool = false
        ) -> (RadarLocationCompletionStore, ManualTimeoutScheduler) {
            let scheduler = ManualTimeoutScheduler()
            let store = RadarLocationCompletionStore(
                scheduleTimeout: scheduler.schedule,
                isStopped: { stopped }
            )
            return (store, scheduler)
        }

        // MARK: - RadarLocationCompletionStore

        @Test("add stores the handler and schedules a 20 second timeout")
        func addSchedulesTimeout() {
            let (store, scheduler) = makeStore()

            store.add(CompletionRecorder().handler)

            #expect(store.count == 1)
            #expect(scheduler.delays == [20])
        }

        @Test("call passes the status, location, and stopped state to every handler, then removes them")
        func callCallsEveryHandler() throws {
            let (store, scheduler) = makeStore(stopped: true)
            let first = CompletionRecorder()
            let second = CompletionRecorder()
            let location = CLLocation(latitude: 40.7, longitude: -73.9)
            store.add(first.handler)
            store.add(second.handler)

            store.call(status: .success, location: location)

            for recorder in [first, second] {
                let call = try #require(recorder.calls.first)
                #expect(recorder.calls.count == 1)
                #expect(call.status == .success)
                #expect(call.location === location)
                #expect(call.stopped)
            }
            #expect(store.count == 0)
            #expect(scheduler.timeouts.allSatisfy { $0.isCancelled })
        }

        @Test("call without waiting handlers does nothing")
        func callWithoutHandlersDoesNothing() {
            let (store, _) = makeStore()

            store.call(status: .success, location: nil)

            #expect(store.count == 0)
        }

        @Test("a timeout fails every waiting handler with a location error")
        func timeoutFailsEveryHandler() throws {
            let (store, scheduler) = makeStore()
            let first = CompletionRecorder()
            let second = CompletionRecorder()
            store.add(first.handler)
            store.add(second.handler)

            try #require(scheduler.timeouts.first).perform()

            #expect(first.calls.map(\.status) == [.errorLocation])
            #expect(second.calls.map(\.status) == [.errorLocation])
            #expect(first.calls.first?.location == nil)
            #expect(store.count == 0)
        }

        @Test("cancelTimeouts cancels the timeouts and keeps the handlers")
        func cancelTimeoutsKeepsHandlers() {
            let (store, scheduler) = makeStore()
            let recorder = CompletionRecorder()
            store.add(recorder.handler)

            store.cancelTimeouts()

            #expect(scheduler.timeouts.allSatisfy { $0.isCancelled })
            #expect(store.count == 1)
            #expect(recorder.calls.isEmpty)

            store.call(status: .success, location: nil)

            #expect(recorder.calls.map(\.status) == [.success])
        }

        @Test("a handler can start a new location request while the store calls it")
        func handlerCanAddDuringCall() {
            let (store, _) = makeStore()
            let next = CompletionRecorder()
            store.add { _, _, _ in
                store.add(next.handler)
            }

            store.call(status: .success, location: nil)

            #expect(store.count == 1)
            #expect(next.calls.isEmpty)
        }

        // MARK: - Static twins

        @Test("the static twins use the installed completion store")
        func staticTwinsUseInstalledStore() {
            RadarLocationManagerSwiftTestHelpers.withRecordingCompletionStore { completions in
                let recorder = CompletionRecorder()

                RadarLocationManagerSwift.addCompletionHandler(recorder.handler)
                RadarLocationManagerSwift.addCompletionHandler(nil)
                #expect(completions.addCallCount == 1)
                #expect(RadarLocationManagerSwift.completionHandlerCount() == 1)

                RadarLocationManagerSwift.cancelTimeouts()
                #expect(completions.cancelTimeoutsCallCount == 1)

                RadarLocationManagerSwift.callCompletionHandlers(status: .errorLocation, location: nil)
                #expect(recorder.calls.map(\.status) == [.errorLocation])
                #expect(RadarLocationManagerSwift.completionHandlerCount() == 0)
            }
        }

        // MARK: - Objective-C dispatch

        @Test("the Objective-C completion methods dispatch to Swift only when useSwiftLocationManager is on", arguments: [true, false])
        func objcCompletionMethodsDispatchByFlag(useSwiftLocationManager: Bool) throws {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": useSwiftLocationManager])

            try RadarLocationManagerSwiftTestHelpers.withRecordingCompletionStore { completions in
                let manager = RadarLocationManager.sharedInstance()
                let addSelector = NSSelectorFromString("addCompletionHandler:")
                let countSelector = NSSelectorFromString("completionHandlerCount")
                let callSelector = NSSelectorFromString("callCompletionHandlersWithStatus:location:")
                try #require(manager.responds(to: addSelector))
                try #require(manager.responds(to: countSelector))
                try #require(manager.responds(to: callSelector))

                let add = unsafeBitCast(manager.method(for: addSelector), to: ObjCAddCompletionHandler.self)
                let count = unsafeBitCast(manager.method(for: countSelector), to: ObjCCompletionHandlerCount.self)
                let call = unsafeBitCast(manager.method(for: callSelector), to: ObjCCallCompletionHandlers.self)

                var statuses: [RadarStatus] = []
                let block: ObjCCompletionBlock = { status, _, _ in statuses.append(status) }

                // The shared manager can still hold handlers that earlier tests added.
                let countBefore = count(manager, countSelector)
                add(manager, addSelector, block)

                #expect(completions.addCallCount == (useSwiftLocationManager ? 1 : 0))
                #expect(count(manager, countSelector) == countBefore + 1)

                call(manager, callSelector, .success, nil)

                #expect(statuses == [.success])
                #expect(completions.statuses == (useSwiftLocationManager ? [.success] : []))
                #expect(count(manager, countSelector) == 0)
            }
        }

        @Test("after useSwiftLocationManager turns on, an Objective-C timeout calls only the Objective-C store")
        func objcTimeoutAfterFlagChangeCallsOnlyObjCStore() throws {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            try RadarLocationManagerSwiftTestHelpers.withRecordingCompletionStore { completions in
                let manager = RadarLocationManager.sharedInstance()
                let addSelector = NSSelectorFromString("addCompletionHandler:")
                let countSelector = NSSelectorFromString("completionHandlerCount")
                let timeoutSelector = NSSelectorFromString("timeoutWithCompletionHandler:")
                try #require(manager.responds(to: addSelector))
                try #require(manager.responds(to: timeoutSelector))
                let add = unsafeBitCast(manager.method(for: addSelector), to: ObjCAddCompletionHandler.self)
                let count = unsafeBitCast(manager.method(for: countSelector), to: ObjCCompletionHandlerCount.self)

                // Start with an empty Objective-C store.
                manager.perform(timeoutSelector, with: nil)

                var objcStatuses: [RadarStatus] = []
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
                add(manager, addSelector, { status, _, _ in objcStatuses.append(status) })

                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": true])
                RadarLocationManagerSwift.addCompletionHandler { _, _, _ in }
                #expect(count(manager, countSelector) == 2)

                manager.perform(timeoutSelector, with: nil)

                #expect(objcStatuses == [.errorLocation])
                #expect(completions.statuses.isEmpty)
                #expect(count(manager, countSelector) == 1)
            }
        }
    }
}
