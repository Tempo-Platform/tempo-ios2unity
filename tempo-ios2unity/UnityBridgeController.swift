//
//  UnityBridgeController.swift
//  tempo-ios2unity
//
//  Created by Stephen Baker on 15/2/2024.
//

import Foundation

public class UnityBridgeController
{
    var onInit: (() -> Void)?
    var onConsentTypeConfirmed: ((String?) -> Void)?
    var onCountryCodeConfirmed: ((String?) -> Void)?
    var onLocDataSuccess: ((String?, String?, String?, String?, String?, String?, String?, String?, String?) -> Void)?
    var onLocDataFailure: ((String?, String?, String?, String?, String?, String?, String?, String?, String?) -> Void)?
    var onSomething: ((String?, String?) -> Void)?
    
    var profile: Profile?
    
    // First step to set core basic that will ve used throughout session
    init() {
        print("💥 UnityBridgeController init()")
    }
    
    func createProfile() {
        print("💥 UnityBridgeController createProfile()")
        profile = Profile(bridge: self)
        profile?.doTaskAfterLocAuthUpdate(completion: nil)
    }
}
