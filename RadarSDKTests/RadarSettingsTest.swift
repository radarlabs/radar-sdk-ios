//
//  RadarSettingsTest.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//


import Foundation
import Testing
@testable
import RadarSDK
import SwiftUI

// run tests in series because we want to test UserDefaults.standard, which is a shared instance
@Suite(.serialized)
actor RadarSettingsTest {
    
    func clearUserDefaults(_ suite: String?) {
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            return
        }
        userDefaults.dictionaryRepresentation().forEach { key, value in
            if (key.starts(with: "radar-")) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    
    @Test("Clones to new UserDefaults on setAppGroup")
    func clonesToNewUserdefaultOnSetAppGroup() {
        clearUserDefaults(nil)
        clearUserDefaults("test.app.group")
        
        let appGroupDefaults = UserDefaults(suiteName: "test.app.group")!
        
        #expect(RadarSettings.userId == nil)
        #expect(appGroupDefaults.string(forKey: "radar-userId") == nil)
        
        RadarSettings.userId = "test"
        
        #expect(RadarSettings.userId == "test")
        #expect(appGroupDefaults.string(forKey: "radar-userId") == nil)
        
        RadarSettings.setAppGroup("test.app.group")
        
        #expect(RadarSettings.userId == "test")
        #expect(UserDefaults(suiteName: "test.app.group")?.string(forKey: "radar-userId") == "test")
    }
    
    @Test("Does not re-clone if the target app group is already initialized")
    func noRepeatedClones() {
        clearUserDefaults(nil)
        clearUserDefaults("test.app.group")
        
        let appGroupDefaults = UserDefaults(suiteName: "test.app.group")!
        
        #expect(RadarSettings.userId == nil)
        
        RadarSettings.userId = "test"
        RadarSettings.setAppGroup("test.app.group")
        
        // simulate initialization from an app extension, which starts off with UserDefault.standard as empty
        clearUserDefaults(nil)
        
        RadarUserDefaults.userDefaults = UserDefaults.standard
        
        #expect(RadarSettings.userId == nil)
        #expect(RadarSettings.getAppGroup() == nil)
        
        #expect(appGroupDefaults.string(forKey: "radar-userId") == "test")
        #expect(appGroupDefaults.string(forKey: "radar-appGroup") == "test.app.group")
        
        RadarSettings.setAppGroup("test.app.group")
        
        #expect(appGroupDefaults.string(forKey: "radar-userId") == "test")
        #expect(appGroupDefaults.string(forKey: "radar-appGroup") == "test.app.group")
        #expect(UserDefaults.standard.string(forKey: "radar-userId") == nil)
        #expect(UserDefaults.standard.string(forKey: "radar-appGroup") == "test.app.group")
        
        #expect(RadarSettings.userId == "test")
        #expect(RadarSettings.getAppGroup() == "test.app.group")
        
        RadarSettings.userId = "updated"
        
        #expect(RadarSettings.userId == "updated")
        #expect(appGroupDefaults.string(forKey: "radar-userId") == "updated")
    }
    
    @Test("Can go back to standard user defaults by setting app group to nil")
    func canGoBackToStandardUserDefaults() {
        clearUserDefaults(nil)
        clearUserDefaults("test.app.group")
        
        let appGroupDefaults = UserDefaults(suiteName: "test.app.group")!
        
        RadarSettings.userId = "test"
        RadarSettings.setAppGroup("test.app.group")
        
        #expect(RadarSettings.userId == "test")
        #expect(appGroupDefaults.string(forKey: "radar-userId") == "test")
        #expect(appGroupDefaults.string(forKey: "radar-appGroup") == "test.app.group")
        
        RadarSettings.userId = "updated"
        
        RadarSettings.setAppGroup(nil)
        
        #expect(RadarSettings.userId == "updated")
        #expect(UserDefaults.standard.string(forKey: "radar-userId") == "updated")
        #expect(UserDefaults.standard.string(forKey: "radar-appGroup") == nil)
        
        RadarSettings.userId = "more-updated"
        RadarSettings.setAppGroup("test.app.group")
        
        #expect(RadarSettings.userId == "more-updated")
        #expect(appGroupDefaults.string(forKey: "radar-userId") == "more-updated")
        #expect(UserDefaults.standard.string(forKey: "radar-appGroup") == "test.app.group")
        #expect(appGroupDefaults.string(forKey: "radar-appGroup") == "test.app.group")
    }
}
