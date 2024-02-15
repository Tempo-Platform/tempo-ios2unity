//
//  Profile.swift
//  tempo-ios2unity
//
//  Created by Stephen Baker on 15/2/2024.
//

import Foundation
import CoreLocation

public class Profile: NSObject, CLLocationManagerDelegate {
    
    // This instance's location manager delegate
    let locManager = CLLocationManager()
    let requestOnLoad_testing = false
    //let adView: TempoAdView
    
    // The static that can be retrieved at any time during the SDK's usage
    static var outputtingLocationInfo = false
    static var locationState: LocationState?
    static var locData: LocationData?
    let bridge: UnityBridgeController
    
    init(bridge: UnityBridgeController) {
        self.bridge = bridge
        super.init()
        print("💥 Profile init()")
        
        // TODO: BACKUPS
        // Update locData with backup if nil
//        if(Profile.locData == nil) {
//            Profile.locData = TempoDataBackup.getMostRecentLocationData()
//        } else {
//            BridgeUtils.Say(msg: "🌏 LocData is null, no backup needed")
//        }
        Profile.updateLocState(newState: Profile.locationState ?? LocationState.UNCHECKED)
        
        // Assign manager delegate
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // For testing, loads when initialised
        if(requestOnLoad_testing) {
            locManager.requestWhenInUseAuthorization()
            locManager.requestLocation()
            requestLocationWithChecks()
        }
    }
    
    private func requestLocationWithChecks() {
        if(Profile.locationState != .CHECKING) {
            Profile.updateLocState(newState: .CHECKING)
            locManager.requestLocation()
        }
        else {
            BridgeUtils.Say(msg: "Ignoring request location as LocationState == CHECKING")
        }
    }
        
    /// Runs async thread process that gets authorization type/accuray and updates LocationData when received
    public func doTaskAfterLocAuthUpdate(completion: (() -> Void)?) {
        
        print("💥 Profile doTaskAfterLocAuthUpdate()")
        // CLLocationManager.authorizationStatus can cause UI unresponsiveness if invoked on the main thread.
        DispatchQueue.global().async {
            
            // Make sure location servics are available
            if CLLocationManager.locationServicesEnabled() {
                
                // get authorisation status
                let authStatus = self.getLocAuthStatus()
                
                switch (authStatus) {
                case .authorizedAlways, .authorizedWhenInUse: // TODO: auth always might not work
                    let addendum = completion == nil ? "No completion task given" : ""
                    BridgeUtils.Say(msg: "✅ Access - always or authorizedWhenInUse [UPDATE] \(addendum)")
                    if #available(iOS 14.0, *) {
                        // iOS 14 intro precise/general options
                        if self.locManager.accuracyAuthorization == .reducedAccuracy {
                            // Update LocationData singleton as GENERAL
                            self.updateLocConsentValues(consentType: BridgeRef.LocationConsent.GENERAL)
                            completion?()
                            return
                        } else {
                            // Update LocationData singleton as PRECISE
                            self.updateLocConsentValues(consentType: BridgeRef.LocationConsent.PRECISE)
                            completion?()
                            return
                        }
                    } else {
                        // Update LocationData singleton as PRECISE (pre-iOS 14 considered precise)
                        self.updateLocConsentValues(consentType: BridgeRef.LocationConsent.PRECISE)
                        completion?()
                        return
                    }
                case .restricted, .denied:
                    BridgeUtils.Warn(msg: "⛔️ No access - restricted or denied [UPDATE]")
                    // Need to update latest valid consent as confirmed NONE
                    Profile.locData = self.getClonedAndCleanedLocation()
                    Profile.updateLocState(newState: LocationState.UNAVAILABLE)
                    self.updateLocConsentValues(consentType: BridgeRef.LocationConsent.NONE)
                    self.saveLatestValidLocData()
                    self.locFailure()
                    completion?()
                    return
                case .notDetermined:
                    BridgeUtils.Warn(msg: "⛔️ No access - notDetermined [UPDATE]")
                    // Need to update latest valid consent as confirmed NONE
                    Profile.locData = self.getClonedAndCleanedLocation()
                    Profile.updateLocState(newState: LocationState.UNAVAILABLE)
                    self.updateLocConsentValues(consentType: BridgeRef.LocationConsent.NONE)
                    self.saveLatestValidLocData()
                    self.locFailure()
                    completion?()
                    return
                @unknown default:
                    BridgeUtils.Warn(msg: "⛔️ Unknown authorization status [UPDATE]")
                }
            } else {
                BridgeUtils.Warn(msg: "⛔️ Location services not enabled [UPDATE]")
            }
            
            Profile.updateLocState(newState: LocationState.UNAVAILABLE)
            self.updateLocConsentValues(consentType: BridgeRef.LocationConsent.NONE)
            self.locFailure()
            completion?()
            
        }
    }
    
    // Updates consent value to both the static object and the adView instance string reference
    private func updateLocConsentValues(consentType: BridgeRef.LocationConsent) {
        Profile.locData?.consent = consentType.rawValue
        if(Profile.outputtingLocationInfo) {
            BridgeUtils.Say(msg: " Updated location consent to: \(consentType.rawValue)")
        }
    }
    
    /// Get CLAuthorizationStatus location consent value
    private func getLocAuthStatus() -> CLAuthorizationStatus {
        var locationAuthorizationStatus : CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            locationAuthorizationStatus =  locManager.authorizationStatus
        } else {
            // Fallback for earlier versions
            locationAuthorizationStatus = CLLocationManager.authorizationStatus()
        }
        return locationAuthorizationStatus
    }
    
    /// Shortcut output for location property types while returning string refererence for metrics
    func getLocationPropertyValue(labelName: String, property: String?) -> String? {
        // TODO: Work out the tabs by string length..?
        if let checkedValue = property {
            if(Profile.outputtingLocationInfo) {
                BridgeUtils.Say(msg: "📍👍 \(labelName): \(checkedValue)")
            }
            return checkedValue
        }
        else {
            if(Profile.outputtingLocationInfo) {
                BridgeUtils.Say(msg: "📍👎 \(labelName): [UNAVAILABLE]")
            }
            return nil
        }
    }
    
    /// Shortcut output for location property types while returning string refererence for metrics
    func getLocationPropertyValue(labelName: String, property: [String]?) -> [String]? {
        // TODO: Work out the tabs by string length..?
        if let checkedValue = property {
            for prop in property! {
                if(Profile.outputtingLocationInfo) {
                    BridgeUtils.Say(msg: "📍👍 \(labelName): \(prop)")
                }
            }
            return checkedValue
        }
        else {
            if(Profile.outputtingLocationInfo) {
                BridgeUtils.Say(msg: "📍👎 \(labelName): [UNAVAILABLE]")
            }
            return nil
        }
    }
   
    /// Updates the fetching state of location data
    public static func updateLocState(newState: LocationState) {
        Profile.locationState = newState
        
        if(Profile.outputtingLocationInfo) {
            BridgeUtils.Say(msg: "🗣️ Updated location state to: \(newState.rawValue)")
        }
        
    }
    
    
    /// Creates and returns new LocationData from current static singleton that doesn't retain its memory references (clears all if NONE consent)
    public func getClonedAndCleanedLocation() -> LocationData {
        
        var newLocData = LocationData()
        let newConsent = Profile.locData?.consent ?? BridgeRef.LocationConsent.NONE.rawValue
        
        newLocData.consent = newConsent
        if(newConsent != BridgeRef.LocationConsent.NONE.rawValue) {
            
            let state = Profile.locData?.state
            let postcode = Profile.locData?.postcode
            let countryCode = Profile.locData?.country_code
            let postalCode = Profile.locData?.postal_code
            let adminArea = Profile.locData?.admin_area
            let subAdminArea = Profile.locData?.sub_admin_area
            let locality = Profile.locData?.locality
            let subLocality = Profile.locData?.sub_locality
            
            newLocData.state = state
            newLocData.postcode = postcode
            newLocData.country_code = countryCode
            newLocData.postal_code = postalCode
            newLocData.admin_area = adminArea
            newLocData.sub_admin_area = subAdminArea
            newLocData.locality = locality
            newLocData.sub_locality = subLocality
        }
        
        return newLocData
    }
    
    /* ---------- Location Manager Callback ---------- */
    /// Location Manager callback: didChangeAuthorization
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        var updating = "NOT UPDATING"
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if(Profile.locationState != .CHECKING) {
                updating = "UPDATING"
                doTaskAfterLocAuthUpdate(completion: nil)
            } else {
                updating = "NOT UPDATING WHILE CHECKING"
            }
            
            requestLocationWithChecks()
        }
        else {
            // The latest change (or first check) showed no valid authorisation: NONE updated
            Profile.updateLocState(newState: LocationState.UNAVAILABLE)
            self.updateLocConsentValues(consentType: BridgeRef.LocationConsent.NONE)
        }
        
        BridgeUtils.Say(msg: "☎️ didChangeAuthorization => \((status as CLAuthorizationStatus).rawValue): \(updating)")
    }
    
    
    func locSuccess() {
        if(Profile.locData == nil) {
            // TODO: Return default NONE
            return
        }
        
        print("✅ locSUCCESS 0");
        let ld = Profile.locData!
        bridge.onLocDataSuccess?(ld.consent ?? "", ld.state ?? "", ld.postcode ?? "", ld.country_code ?? "", ld.postal_code ?? "", ld.admin_area ?? "", ld.sub_admin_area ?? "", ld.locality ?? "", ld.sub_locality ?? "");
    }
    
    
    func locFailure() {
        if(Profile.locData == nil) {
            // TODO: Return default NONE
            return
        }
        
        let ld = Profile.locData!
        print("❌ locFailure 2");
        print("❌ locFailure 2A: \(ld.consent ?? "WTF!?!?!?!")");
        if(ld == nil) {
            print("❌ naw, it nil bra");
        }
        
        let consent = ld.consent ?? ""
        let state = ld.state ?? ""
        let postcode = ld.postcode ?? ""
        let country_code = ld.country_code ?? ""
        let postal_code = ld.postal_code ?? ""
        let admin_area = ld.admin_area ?? ""
        let sub_admin_area = ld.sub_admin_area ?? ""
        let locality = ld.locality ?? ""
        let sub_locality = ld.sub_locality ?? ""
        print("❌ locFailure I \(sub_locality): \(sub_locality != nil)")
        
        
        //bridge.onSomething?(consent, state)
    
        if let onLocDataFailure = bridge.onLocDataFailure {
            onLocDataFailure(consent, state, postcode, country_code, postal_code, admin_area, sub_admin_area, locality, sub_locality)
            //onLocDataFailure("", "", "", "", "", "", "", "", "")
            print("Sent!")
        } else {
            print("Error: onLocDataFailure is nil")
        }
        print("❌ locFailure K");
    }
    
    /// Location Manager callback: didUpdateLocations
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        var errorMsg: String?
        BridgeUtils.Say(msg: "☎️ didUpdateLocations: \(locations.count)")
        
        // Last location is most recent (i.e. most accurate)
        if let location = locations.last {
            
            // Reverse geocoding to get the location properties
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            
                if let error = error {
                    errorMsg = "Reverse geocoding failed with error: \(error.localizedDescription) | Values remain unchanged"
                    self.locFailure()
                    Profile.updateLocState(newState: LocationState.FAILED)
                    self.locFailure()
                }
                else {
                    if let placemark = placemarks?.first {
                        
                        Profile.locData?.state = self.getLocationPropertyValue(labelName: "State", property: placemark.administrativeArea)
                        Profile.locData?.postcode = self.getLocationPropertyValue(labelName: "Postcode", property: placemark.postalCode)
                        Profile.locData?.postal_code = self.getLocationPropertyValue(labelName: "Postal Code", property: placemark.postalCode)
                        Profile.locData?.country_code = self.getLocationPropertyValue(labelName: "Country Code", property: placemark.isoCountryCode)
                        Profile.locData?.admin_area = self.getLocationPropertyValue(labelName: "Admin Area", property: placemark.administrativeArea)
                        Profile.locData?.sub_admin_area = self.getLocationPropertyValue(labelName: "Sub Admin Area", property: placemark.subAdministrativeArea)
                        Profile.locData?.locality = self.getLocationPropertyValue(labelName: "Locality", property: placemark.locality)
                        Profile.locData?.sub_locality = self.getLocationPropertyValue(labelName: "Sub Locality", property: placemark.subLocality)
                        
                        let testingOutput = false
                        if(testingOutput) {
//                        print("🌐 => \(location.coordinate.latitude)/\(location.coordinate.longitude)" )
//                        self.getLocationPropertyValue(labelName: "name", property: placemark.name) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "thoroughfare", property: placemark.thoroughfare) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "subThoroughfare", property: placemark.subThoroughfare) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "locality", property: placemark.locality) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "subLocality", property: placemark.subLocality) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "administrativeArea", property: placemark.administrativeArea) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "subAdministrativeArea", property: placemark.subAdministrativeArea) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "postalCode", property: placemark.postalCode) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "isoCountryCode", property: placemark.isoCountryCode) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "country", property: placemark.country) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "inlandWater", property: placemark.inlandWater) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "ocean", property: placemark.ocean) ?? "n/a"
//                        self.getLocationPropertyValue(labelName: "areasOfInterest", property: placemark.areasOfInterest) ?? []
                        }
                        
                        // Update current sessions top-level country code paramter is there is a value
                        
                        // TODO: Update Country Code...?
//                        if let cc = Profile.locData?.country_code, !cc.isEmpty {
//                            self.adView.countryCode = cc
//                        }
                        
                        BridgeUtils.Say(msg: "☎️ didUpdateLocations: [admin=\(Profile.locData?.admin_area ?? "nil") | locality=\(Profile.locData?.locality ?? "nil")] | Values have been updated")
                        
                        // Save data instance as most recently validated data
                        self.saveLatestValidLocData()
                        
                        Profile.updateLocState(newState: LocationState.CHECKED)
                        self.locSuccess()
                        return
                    }
                }
                
                BridgeUtils.Warn(msg: "☎️ didUpdateLocations: [errorMsg: \(errorMsg ?? "UNKNOWN")]] | Values remain unchanged have been updated")
                
            }
        } else {
            BridgeUtils.Warn(msg: "☎️ didUpdateLocations: [errorMsg: \(errorMsg ?? "UNKNOWN")]] | Values remain unchanged have been updated")
            Profile.updateLocState(newState: LocationState.FAILED)
            locFailure()
            return
        }
    }
    
    
    private func saveLatestValidLocData() {
        
        // Save the instance to UserDefaults
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(Profile.locData) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: BridgeRef.LOC_BACKUP_REF)
            BridgeUtils.Say(msg: "Backup location data saved")
        }
        else {
            BridgeUtils.Warn(msg: "Backup location data saved")
        }
    }
    
    /// Location Manager callback: didFailWithError
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        BridgeUtils.Say(msg: "☎️ didFailWithError: \(error)")
        //locManager.stopUpdatingLocation()
        
        if let clErr = error as? CLError {
            switch clErr.code {
            case .locationUnknown, .denied, .network:
                print("Location request failed with error: \(clErr.localizedDescription)")
            case .headingFailure:
                print("Heading request failed with error: \(clErr.localizedDescription)")
            case .rangingUnavailable, .rangingFailure:
                print("Ranging request failed with error: \(clErr.localizedDescription)")
            case .regionMonitoringDenied, .regionMonitoringFailure, .regionMonitoringSetupDelayed, .regionMonitoringResponseDelayed:
                print("Region monitoring request failed with error: \(clErr.localizedDescription)")
            default:
                print("Unknown location manager error: \(clErr.localizedDescription)")
            }
        } else {
            print("Unknown error occurred while handling location manager error: \(error.localizedDescription)")
        }
        
        // Need to start pushing these for this round
        Profile.updateLocState(newState: LocationState.FAILED)
        locFailure()
    }
    
    
    /* ---------- TESTING---------- */
    /// Public function for prompting consent (used for testing)
    public func requestLocationConsentNowAsTesting() {
        BridgeUtils.Say(msg: "🪲🪲🪲 requestLocationConsent")
        locManager.requestWhenInUseAuthorization()
        
        requestLocationWithChecks()
    }
    
    public static func getMostRecentLocationData() -> LocationData {
        
        // To retrieve the instance from UserDefaults:
        if let savedLocationData = UserDefaults.standard.data(forKey: BridgeRef.LOC_BACKUP_REF),
            let decodedLocation = try? JSONDecoder().decode(LocationData.self, from: savedLocationData) {
            // Use the retrieved location data
            print( "🌎 Most recent location backed up: admin=\(decodedLocation.admin_area ?? "nil"), locality=\(decodedLocation.locality ?? "nil")")
            return decodedLocation
        } else {
            print("🌎 Failed to backup most recent location")
        }
        
        return LocationData()
    }
}

public class LocationData : Codable {
    var consent: String?
    var postcode: String?
    var state: String?
    
    var postal_code: String?
    var country_code: String?
    var admin_area: String?
    var sub_admin_area: String?
    var locality: String?
    var sub_locality: String?
    
    init(consent: String) {
        self.consent = consent
        defaultValues()
    }
    
    init() {
        consent = "\(BridgeRef.LocationConsent.NONE)"
        defaultValues()
    }
    
    func defaultValues() {
        postcode = ""
        state = ""
        postal_code = ""
        country_code = ""
        admin_area = ""
        sub_admin_area = ""
        locality = ""
        sub_locality = ""
    }
}

public enum LocationState: String {
    case UNCHECKED
    case CHECKING
    case CHECKED
    case FAILED
    case UNAVAILABLE
}
