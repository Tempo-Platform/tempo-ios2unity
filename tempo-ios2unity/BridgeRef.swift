public struct BridgeRef {
    
    static let ZERO_AD_ID = "00000000-0000-0000-0000-000000000000"
    static let LOC_BACKUP_REF = "locationData"
    static var isTesting = true
    
    public enum LocationConsent: String {
        case NONE
        case GENERAL
        case PRECISE
    }
}
