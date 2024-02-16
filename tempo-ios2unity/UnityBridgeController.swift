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
    var onConsentTypeConfirmed: ((UnsafePointer<CChar>?, Int) -> Void)?
    var onCountryCodeConfirmed: ((UnsafePointer<CChar>?) -> Void)?
    var onLocDataSuccess: ((String, String, String, String, String, String, String, String, String) -> Void)?
    var onLocDataFailure: ((String, String, String, String, String, String, String, String, String) -> Void)?
    
    var profile: Profile?
    var bridge: UnityBridgeController?
    
    // First step to set core basic that will ve used throughout session
    override init() {
        print("💥 UnityBridgeController init()")
    }
    
    func initBridge(bridgeController: UnityBridgeController) {
        print("💥 UnityBridgeController initBridge()")
        bridge = bridgeController
        //sendSomethingToUnity(someString: "hello", someInt: 69)
    }
    
    func sendSomethingToUnity(someInt: Int) {
        let someString: String = "hello"
        if let onSomething = bridge?.onSomething {
            print("⚡️ something => \(String(describing: charPointerConverter(someString))) + \(someInt)")
            onSomething(charPointerConverter(someString), someInt)
            print("⚡️ Sent!")
        } else {
            print("Error: sendSomethingToUnity is nil")
        }
        
        let consentValue = BridgeRef.LocationConsent.NONE.rawValue //"hell2" //
        if let onConsentTypeConfirmed = bridge?.onConsentTypeConfirmed {
            print("⚡️ consent => \(String(describing: charPointerConverter(consentValue)))")
            onConsentTypeConfirmed(charPointerConverter(consentValue), 69)
            print("⚡️ Sent!")
        } else {
            print("Error: onConsentTypeConfirmed is nil")
        }
        
        DispatchQueue.global().async {
            
            self.profile?.sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent.NONE)
        }
    }
    
    func convertStringtoCChar(myPerfectlyGoodString: String) -> [CChar] {
        var cCharArray: [CChar] = []

        myPerfectlyGoodString.withCString { cString in
            // Iterate through the C string until the null terminator is encountered
            var pointer = cString
            while pointer.pointee != 0 {
                cCharArray.append(pointer.pointee)
                pointer = pointer.advanced(by: 1)
            }
        }

        return cCharArray
    }
    func createProfile() {
        print("💥 UnityBridgeController createProfile()")
        profile = Profile(bridgeController: bridge!)
        profile?.doTaskAfterLocAuthUpdate(completion: nil)
    }
    
    public func charPointerConverter(_ paramString: String) -> UnsafePointer<CChar>? {
        return paramString.withCString { cString in
            guard let duplicatedString = strdup(cString) else {
                return nil
            }
            return UnsafePointer(duplicatedString)
        }
    }
    
    
    /// Checks to make sure object sent through is a valid string
    private func charPointerValidator(paramString: UnsafePointer<CChar>?) -> String! {
        
        guard let paramString else {
            print("❌ paramString was null")
            return nil
        }
        
        if let validatedString = String(validatingUTF8: paramString ) {
            //print("✅ charPointer validated => \(validatedString) <=")
            return validatedString
        }
        else {
            print("❌ wrong input format (paramString)")
            return nil
        }
    }

}
