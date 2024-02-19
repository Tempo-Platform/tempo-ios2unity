import Foundation
import CoreLocation
import AdSupport

public class Profile: NSObject, CLLocationManagerDelegate {
    
    let locManager = CLLocationManager() // this instance's location manager delegate
    let requestOnLoad_testing = false // make true to prompt location consent at runtime
    var outputtingLocationInfo = true // outputs additional info during runtime
    var locationState: LocationState = LocationState.UNCHECKED // state of current request process
    var locData: LocationData = LocationData(consent: BridgeRef.LocationConsent.NONE.rawValue) // holds all location properties
    let bridge: UnityBridgeController // reference to platform mediator
    
    /// Initialiser constructor, sets up location config parameters
    init(bridgeController: UnityBridgeController) {
        print("💥 Profile.init()")
        
        bridge = bridgeController
        super.init()
        
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

    
    /* ---------- Task  ---------- */
    /// Runs async thread process that gets authorization type/accuray and updates LocationData when received
    public func doTaskAfterLocAuthUpdate(completion: (() -> Void)?) {
        print("💥 Profile.doTaskAfterLocAuthUpdate()")
        
        // CLLocationManager.authorizationStatus can cause UI unresponsiveness if invoked on the main thread.
        DispatchQueue.global().async {
            
            // Make sure location servics are available
            if CLLocationManager.locationServicesEnabled() {
                
                // get authorisation status
                let authStatus = self.getLocAuthStatus()
                
                switch (authStatus) {
                case .authorizedAlways, .authorizedWhenInUse: // TODO: auth always might not work
                    BridgeUtils.Say(msg: "✅ Access - always or authorizedWhenInUse [UPDATE] \(completion == nil ? "No completion task given" : "")")
                    self.locData = self.loadLastValidLocData()
                    
                    if #available(iOS 14.0, *) {
                        
                        // iOS 14 intro precise/general options
                        if self.locManager.accuracyAuthorization == .reducedAccuracy {
                            // Update LocationData singleton as GENERAL
                            self.locData.consent = BridgeRef.LocationConsent.GENERAL.rawValue;
                            self.sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent.GENERAL)
                            
                            // Run completion
                            completion?()
                            return
                            
                        } else {
                            // Update LocationData singleton as PRECISE
                            self.locData.consent = BridgeRef.LocationConsent.PRECISE.rawValue;
                            self.sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent.PRECISE)
                            
                            // Run completion
                            completion?()
                            return
                        }
                        
                    } else {
                        // Update LocationData singleton as PRECISE (pre-iOS 14 considered precise)
                        self.locData.consent = BridgeRef.LocationConsent.PRECISE.rawValue;
                        self.sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent.PRECISE)
                        
                        // Run completion
                        completion?()
                        return
                    }
                    
                case .restricted, .denied:
                    BridgeUtils.Warn(msg: "⛔️ No access - restricted or denied [UPDATE]")
//                    
//                    // Need to update latest valid consent as confirmed NONE
//                    self.locData = LocationData(consent: BridgeRef.LocationConsent.NONE.rawValue)
//                    self.updateLocState(newState: LocationState.UNAVAILABLE)
//                    
//                    // Update Unity
//                    //self.sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent.NONE)
//                    self.locFailure()
//                    
//                    // Save and run completion
//                    self.saveValidLocData()
//                    completion?()
//                    return
                    break
                    
                case .notDetermined:
                    BridgeUtils.Warn(msg: "⛔️ No access - notDetermined [UPDATE]")
//                    
//                    // Need to update latest valid consent as confirmed NONE
//                    self.locData = LocationData(consent: BridgeRef.LocationConsent.NONE.rawValue)
//                    self.updateLocState(newState: LocationState.UNAVAILABLE)
//                    
//                    // Update Unity
//                    self.sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent.NONE)
//                    self.locFailure()
//                    
//                    // Save and run completion
//                    self.saveValidLocData()
//                    completion?()
//                    return
                    break
                @unknown default:
                    BridgeUtils.Warn(msg: "⛔️ Unknown authorization status [UPDATE]")
                }
            } else {
                BridgeUtils.Warn(msg: "⛔️ Location services not enabled [UPDATE]")
            }
            
            // Need to update latest valid consent as confirmed NONE
            self.locData = LocationData(consent: BridgeRef.LocationConsent.NONE.rawValue)
            self.updateLocState(newState: LocationState.UNAVAILABLE)
            
            // Update Unity
            self.sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent.NONE)
            self.locFailure()
            
            // Save and run completion
            self.saveValidLocData()
            completion?()
            
        }
    }
    
    /// Sends latest LocData values when a successful up-to-date check has been done
    func locSuccess() {
        print("✅ Profile.locSuccess");
        let ld = locData
        if let onLocDataSuccess = bridge.onLocDataSuccess {
            onLocDataSuccess(ld.consent , ld.state , ld.postcode , ld.country_code , ld.postal_code , ld.admin_area , ld.sub_admin_area , ld.locality , ld.sub_locality)
            print("Profile.locSuccess() - SENT consent=\(ld.consent)")
        } else {
            print("Error: onLocDataSuccess is nil")
        }
    }
    
    /// Sends latest LocData values when an up-to-date check has failed - will rely on previous record (or NONE if default)
    func locFailure() {
        print("❌ Profile.locFailure");
        let ld = locData
        if let onLocDataFailure = bridge.onLocDataFailure {
            onLocDataFailure(ld.consent , ld.state , ld.postcode , ld.country_code , ld.postal_code , ld.admin_area , ld.sub_admin_area , ld.locality , ld.sub_locality)
            print("Profile.locFailure() - SENT consent=\(ld.consent)")
        } else {
            print("Error: onLocDataFailure is nil")
        }
    }
    
    /// Save instance of LocationData
    private func saveValidLocData() {
        // Save the instance to UserDefaults
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(locData) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: BridgeRef.LOC_BACKUP_REF)
            BridgeUtils.Say(msg: "Backup location data saved")
        }
        else {
            BridgeUtils.Warn(msg: "Backup location data saved")
        }
    }
    
    /// Retrieves instance of LocationData
    public func loadLastValidLocData() -> LocationData {
        // To retrieve the instance from UserDefaults:
        if let savedLocationData = UserDefaults.standard.data(forKey: BridgeRef.LOC_BACKUP_REF),
            let decodedLocation = try? JSONDecoder().decode(LocationData.self, from: savedLocationData) {
            // Use the retrieved location data
            BridgeUtils.Say(msg: "🌎 Most recent location backed up: consent=\(decodedLocation.consent), admin=\(decodedLocation.admin_area), locality=\(decodedLocation.locality)")
            return decodedLocation
        } else {
            BridgeUtils.Warn(msg: "🌎 Failed to backup most recent location")
        }
        
        return LocationData()
    }
    
    
    /* ---------- GET ---------- */
    /// Get CLAuthorizationStatus location consent value
    func getLocAuthStatus() -> CLAuthorizationStatus {
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
            if(outputtingLocationInfo) {
                BridgeUtils.Say(msg: "📍👍 \(labelName): \(checkedValue)")
            }
            return checkedValue
        }
        else {
            if(outputtingLocationInfo) {
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
                if(outputtingLocationInfo) {
                    BridgeUtils.Say(msg: "📍👍 \(labelName): \(prop)")
                }
            }
            return checkedValue
        }
        else {
            if(outputtingLocationInfo) {
                BridgeUtils.Say(msg: "📍👎 \(labelName): [UNAVAILABLE]")
            }
            return nil
        }
    }
    
    /// Creates and returns new LocationData from current static singleton that doesn't retain its memory references (clears all if NONE consent)
    public func getClonedAndCleanedLocation() -> LocationData {
        
        let newLocData = LocationData()
        let newConsent = locData.consent
        
        newLocData.consent = newConsent
        if(newConsent != BridgeRef.LocationConsent.NONE.rawValue) {
            
            let state = locData.state
            let postcode = locData.postcode
            let countryCode = locData.country_code
            let postalCode = locData.postal_code
            let adminArea = locData.admin_area
            let subAdminArea = locData.sub_admin_area
            let locality = locData.locality
            let subLocality = locData.sub_locality
            
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
    
    /// Manually call for a location data (will trigger consent request if not confirmed yet!) TODO: Not sure what this actually is????
    func requestLocationWithChecks() {
        if(locationState != .CHECKING) {
            updateLocState(newState: .CHECKING)
            locManager.requestLocation()
        }
        else {
            BridgeUtils.Say(msg: "Ignoring request location as LocationState == CHECKING")
        }
    }
    
    // Cnecks is consented Ad ID exists and returns value
    func getAdId() -> String! {
        // Get Advertising ID (IDFA) // TODO: add proper IDFA alternative here if we don't have Ad ID
        let advertisingIdentifier: UUID = ASIdentifierManager().advertisingIdentifier
        return advertisingIdentifier.uuidString != BridgeRef.ZERO_AD_ID ? advertisingIdentifier.uuidString : nil
    }
    
    
    /* ---------- SET ---------- */
    /// Trigger callback with consent type to update Unity
    public func sendConsentUpdateToUnity(lc: BridgeRef.LocationConsent) {
        let rawValue = lc.rawValue
        if let onConsentTypeConfirmed = bridge.onConsentTypeConfirmed {
            onConsentTypeConfirmed(BridgeUtils.charPointerConverter(rawValue))
        } else {
            print("Error: onConsentTypeConfirmed is nil")
        }
    }
    
    /// Updates the fetching state of location data
    public func updateLocState(newState: LocationState) {
        locationState = newState
        
        if(outputtingLocationInfo) {
            BridgeUtils.Say(msg: "🗣️ Updated location state to: \(newState.rawValue)")
        }
    }
    
    
    
    /* ---------- Location Manager Callback ---------- */
    /// Location Manager callback: didChangeAuthorization
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        var tag = ""
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            
            // If something changed and not already checking, checking again...
            if(locationState != .CHECKING) {
                tag = "Not CHECKING (so updating again...)"
                doTaskAfterLocAuthUpdate(completion: nil)
            } else {
                tag = "Already CHECKING (so ignoring update request...)"
            }
            
            requestLocationWithChecks()
        }
        else {
            // The latest change (or first check) showed no valid authorisation: NONE updated
            tag = "Unauthorised, state made UNAVAILABLE, consent made NONE"
            updateLocState(newState: LocationState.UNAVAILABLE)
            locData = LocationData(consent: BridgeRef.LocationConsent.NONE.rawValue)
        }
        
        BridgeUtils.Say(msg: "🌎 didChangeAuthorization => \((status as CLAuthorizationStatus).rawValue): \(tag)")
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
                    self.updateLocState(newState: LocationState.FAILED)
                    self.locFailure()
                }
                else {
                    if let placemark = placemarks?.first {
                        
                        self.locData.state = self.getLocationPropertyValue(labelName: "State", property: placemark.administrativeArea) ?? ""
                        self.locData.postcode = self.getLocationPropertyValue(labelName: "Postcode", property: placemark.postalCode) ?? ""
                        self.locData.postal_code = self.getLocationPropertyValue(labelName: "Postal Code", property: placemark.postalCode) ?? ""
                        self.locData.country_code = self.getLocationPropertyValue(labelName: "Country Code", property: placemark.isoCountryCode) ?? ""
                        self.locData.admin_area = self.getLocationPropertyValue(labelName: "Admin Area", property: placemark.administrativeArea) ?? ""
                        self.locData.sub_admin_area = self.getLocationPropertyValue(labelName: "Sub Admin Area", property: placemark.subAdministrativeArea) ?? ""
                        self.locData.locality = self.getLocationPropertyValue(labelName: "Locality", property: placemark.locality) ?? ""
                        self.locData.sub_locality = self.getLocationPropertyValue(labelName: "Sub Locality", property: placemark.subLocality) ?? ""
                        BridgeUtils.Say(msg: "☎️ didUpdateLocations: [admin=\(self.locData.admin_area) | locality=\(self.locData.locality)] | Values have been updated")
                        
                        // Save data instance as most recently validated data
                        self.saveValidLocData()
                        
                        self.updateLocState(newState: LocationState.CHECKED)
                        self.locSuccess()
                        return
                    }
                }
                
                BridgeUtils.Warn(msg: "☎️ didUpdateLocations: [errorMsg: \(errorMsg ?? "UNKNOWN")]] | Values remain unchanged have been updated")
                
            }
        } else {
            BridgeUtils.Warn(msg: "☎️ didUpdateLocations: [errorMsg: \(errorMsg ?? "UNKNOWN")]] | Values remain unchanged have been updated")
            updateLocState(newState: LocationState.FAILED)
            locFailure()
            return
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
        updateLocState(newState: LocationState.FAILED)
        locFailure()
    }
    
    
    /* ---------- TESTING---------- */
    /// Public function for prompting consent (used for testing)
    public func requestLocationConsentNowAsTesting() {
        BridgeUtils.Say(msg: "🪲🪲🪲 requestLocationConsent")
        locManager.requestWhenInUseAuthorization()
        
        requestLocationWithChecks()
    }
    

}

public class LocationData : Codable {
    var consent: String = ""
    var postcode: String = ""
    var state: String = ""
    
    var postal_code: String = ""
    var country_code: String = ""
    var admin_area: String = ""
    var sub_admin_area: String = ""
    var locality: String = ""
    var sub_locality: String = ""
    
    init(consent: String) {
        self.consent = consent
        defaultValues()
    }
    
    init() {
        consent = "\(BridgeRef.LocationConsent.NONE.rawValue)"
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
