//
//  UnityBridgeController.swift
//  tempo-ios2unity
//
//  Created by Stephen Baker on 15/2/2024.
//

import Foundation

public class UnityBridgeController: NSObject
{
    var onInit: (() -> Void)?
    var onSomething: ((UnsafePointer<CChar>?, Int) -> Void)?
    var onConsentTypeConfirmed: ((UnsafePointer<CChar>?) -> Void)?
    var onCountryCodeConfirmed: ((UnsafePointer<CChar>?) -> Void)?
    var onAdIdConfirmed: ((UnsafePointer<CChar>?) -> Void)?
    var onLocDataSuccess: ((UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void)?
    var onLocDataFailure: ((UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void)?
    
    var profile: Profile?
    var bridge: UnityBridgeController?
    public var countryCode: String = ""
    
    // First step to set core basic that will ve used throughout session
    override init() {   /* Nothing needs to happen here */ }
    
    func initBridge(bridgeController: UnityBridgeController) {
        print("💥 UnityBridgeController.initBridge()")
        bridge = bridgeController
        getCountryCode()
        onInit?()
    }
    
    func createProfile() {
        print("💥 UnityBridgeController.createProfile()")
        profile = Profile(bridgeController: bridge!)
        getAdId()
        profile?.doTaskAfterLocAuthUpdate(completion: nil)
    }
    
    func getAdId() {
        let adId = profile?.getAdId() ?? BridgeRef.ZERO_AD_ID
        print("💥 UnityBridgeController.getAdId() -> \(adId)")
        onAdIdConfirmed?(adId)
    }
    
    func getCountryCode() {
        countryCode = CountryCode.getIsoCountryCode2Digit() ?? ""
        print("💥 UnityBridgeController.getCountryCode() -> \(countryCode)")
        onCountryCodeConfirmed?(BridgeUtils.charPointerConverter(countryCode))
    }
    
    func sendSomethingToUnity(someInt: Int) {
//        if let onConsentTypeConfirmed = bridge?.onConsentTypeConfirmed {
//            print("⚡️ consent => \(String(describing: charPointerConverter(consentValue)))")
//            onConsentTypeConfirmed(charPointerConverter(consentValue), 69)
//            print("⚡️ Sent!")
//        } else {
//            print("Error: onConsentTypeConfirmed is nil")
//        }
    }
}
