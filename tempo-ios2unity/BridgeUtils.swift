//
//  BridgeUtils.swift
//  tempo-ios2unity
//
//  Created by Stephen Baker on 15/2/2024.
//


import Foundation
import CoreLocation


public class ResponseBadRequest: Decodable {
    var error: String?
    var status: String?
    
    public func outputValues() {
        BridgeUtils.Warn(msg: "[400]: status=\(status ?? "nil"), error=\(error ?? "nil")")
    }
}

public class ResponseUnprocessable: Decodable {
    var detail: [UnprocessableDetail]?
    
    public func outputValues() {
        if(detail != nil && detail!.count > 0) {
            for detail in detail! {
                BridgeUtils.Warn(msg: "[422]: msg=\(detail.msg ?? "nil"), type=\(detail.type ?? "nil"), loc=\(detail.loc ?? ["n/a"])")
            }
        }
        
    }
}

public class UnprocessableDetail: Decodable {
    var loc: [String]?
    var msg: String?
    var type: String?
    
    private enum CodingKeys: String, CodingKey {
            case loc
            case msg
            case type
        }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            loc = try container.decodeIfPresent([String].self, forKey: .loc)
            msg = try container.decodeIfPresent(String.self, forKey: .msg)
            type = try container.decode(String.self, forKey: .type)
        }
    
}


public class ResponseSuccess: Decodable {
    var status: String?
    var cpm: Float?
    var id: String?
    var location_url_suffix: String?
    
    public func outputValues() {
        BridgeUtils.Say(msg: "[200]: Status=\(status ?? "nil"), CampaignID=\(id ?? "nil"), CPM=\(cpm ?? 0), Suffix=\(location_url_suffix ?? "nil")", absoluteDisplay: true)
    }
}
    
    /**
     * Global tools to use within the Tempo SDK module
     */
public class BridgeUtils {
    
    /// Log for URGENT output with 🔴 marker - not to be used in production
    public static func Shout(msg: String) {
        if(BridgeRef.isTesting) {
            print("🔴 TempoSDK: \(msg)");
        }
    }
    
    /// Log for URGENT output with 🔴 marker, even when TESTING is on - not to be used in production
    public static func Shout(msg: String, absoluteDisplay: Bool) {
        if (absoluteDisplay) {
            print("🔴 TempoSDK: \(msg)");
        } else if (BridgeRef.isTesting) {
            // Nothing - muted
        }
    }
    
    /// Log for general test  output -, never shows in production
    public static func Say(msg: String) {
        if(BridgeRef.isTesting) {
            print("🟣 TempoSDK: \(msg)");
        }
    }
    
    /// Log for general output with - option of toggling production output or off completely
    public static func Say(msg: String, absoluteDisplay: Bool) {
        if (absoluteDisplay) {
            print("TempoSDK: \(msg)");
        } else if (BridgeRef.isTesting) {
            // Nothing - muted
        }
    }
    
    /// Log for WARNING output with ⚠️ marker - not to be used in production
    public static func Warn(msg: String) {
        if(BridgeRef.isTesting) {
            print("⚠️ TempoSDK: \(msg)");
        }
    }
    
    /// Log for WARNING output with ⚠️ marker, option of toggling production output or off completely
    public static func Warn(msg: String, absoluteDisplay: Bool) {
        if (absoluteDisplay) {
            print("⚠️ TempoSDK: \(msg)");
        } else if (BridgeRef.isTesting) {
            // Nothing - muted
        }
    }
    
}
