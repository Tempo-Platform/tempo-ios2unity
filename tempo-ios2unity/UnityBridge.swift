//
//  UnityBridge.swift
//  tempo-ios2unity
//
//  Created by Stephen Baker on 15/2/2024.
//

import Foundation

var bridgeController: UnityBridgeController?

/* CALLOUTS */
@_cdecl("initBridge")
public func initBridge() {
    // create bridge controller
    bridgeController = UnityBridgeController()
}

@_cdecl("checkPrecise")
public func checkPrecise() {
    // call 'checkPrecise' to initiate device geocheck
}

@_cdecl("checkGeneral")
public func checkGeneral() {
    // call 'checkGeneral' to initiate device geocheck
}

@_cdecl("createProfile") 
public func createProfile() {
    // call 'createProfile' in controller to start collecting Profile data
    bridgeController?.createProfile()
}


/* DELEGATES */
@_cdecl("set_OnInitDelegate")
public func set_OnInitDelegate(delegate: @convention(c) @escaping () -> Void) {
    bridgeController?.onInit = delegate
}

@_cdecl("set_OnConsentTypeConfirmedDelegate")
public func set_OnConsentTypeConfirmedDelegate(delegate: @convention(c) @escaping (String?) -> Void) {
    bridgeController?.onConsentTypeConfirmed = delegate
}

@_cdecl("set_OnCountryCodeConfirmedDelegate")
public func set_OnCountryCodeConfirmedDelegate(delegate: @convention(c) @escaping (String?) -> Void) {
    bridgeController?.onCountryCodeConfirmed = delegate
}

@_cdecl("set_OnLocDataSuccessDelegate")
public func set_OnLocDataSuccessDelegate(delegate: @convention(c) @escaping (String?, String?, String?, String?, String?, String?, String?, String?, String?) -> Void) {
    bridgeController?.onLocDataSuccess = delegate
}

@_cdecl("set_OnLocDataFailureDelegate")
public func set_OnLocDataFailureDelegate(delegate: @convention(c) @escaping (String?, String?, String?, String?, String?, String?, String?, String?, String?) -> Void) {
    bridgeController?.onLocDataFailure = delegate
}

@_cdecl("set_OnSomethingDelegate")
public func set_OnSomethingDelegate(delegate: @convention(c) @escaping (String?, String?) -> Void) {
    bridgeController?.onSomething = delegate
}
