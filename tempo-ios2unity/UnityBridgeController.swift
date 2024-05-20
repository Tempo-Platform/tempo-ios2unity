import Foundation

public class UnityBridgeController: NSObject
{
    // Delelgates
    var onInit: (() -> Void)?
    var onConsentTypeConfirmed: ((UnsafePointer<CChar>?) -> Void)?
    var onCountryCodeConfirmed: ((UnsafePointer<CChar>?) -> Void)?
    var onAdIdConfirmed: ((UnsafePointer<CChar>?) -> Void)?
    var onLocDataSuccess: ((UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, 
                            UnsafePointer<CChar>?,UnsafePointer<CChar>?, UnsafePointer<CChar>?,
                            UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void)?
    var onLocDataFailure: ((UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?,
                            UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?,
                            UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void)?
    var onSomething: ((UnsafePointer<CChar>?, Int) -> Void)?
    
    // Bridge properties
    var bridge: UnityBridgeController? // go-between
    var profile: Profile? // user data collection
    public var countryCode: String = ""
    
    /// First step to set core basic that will ve used throughout session
    override init() {   /* Nothing needs to happen here */ }
    
    /// Initialises mediator class and get cc straight away
    func initBridge(bridgeController: UnityBridgeController) {
        print("💥 UnityBridgeController.initBridge()")
        bridge = bridgeController
        getCountryCode()
        onInit?()
    }
    
    /// Starts process of collecting user profiling data (location, Ad ID etc)
    func createProfile() {
        print("💥 UnityBridgeController.createProfile()")
        profile = Profile(bridgeController: bridge!)
        getAdId()
        profile?.doTaskAfterLocAuthUpdate(completion: nil)
    }
    
    /// Returns Ad ID, if setup on user's device
    func getAdId() {
        let adId = profile?.getAdId() ?? BridgeRef.ZERO_AD_ID
        print("💥 UnityBridgeController.getAdId() -> \(adId)")
        onAdIdConfirmed?(adId)
    }
    
    /// Returns 2-digit ISO country code from device settings
    func getCountryCode() {
        countryCode = CountryCode.getIsoCountryCode2Digit() ?? ""
        print("💥 UnityBridgeController.getCountryCode() -> \(countryCode)")
        onCountryCodeConfirmed?(BridgeUtils.charPointerConverter(countryCode))
    }
    
    /// Test function to send back String/Int to Unity
    func sendSomethingToUnity(someString: UnsafePointer<CChar>?, someInt: Int) {
        if let onSomething = bridge?.onSomething {
            print("something => \(someInt))")
            onSomething(someString, someInt)
        } else {
            print("Error: onSomething is nil")
        }
    }
    
    /// Test function to send back String/Int to Unity
    func requestLocationConsent() {
        profile?.requestLocationConsentNowAsTesting()
    }
}
