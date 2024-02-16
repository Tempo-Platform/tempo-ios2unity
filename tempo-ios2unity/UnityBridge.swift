//
//  UnityBridge.swift
//  tempo-ios2unity
//
//  Created by Stephen Baker on 15/2/2024.
//

import Foundation
import CoreLocation

var bridgeController = UnityBridgeController()



/* CALLOUTS */
@_cdecl("initBridge")
public func initBridge() {
    // create bridge controller
    bridgeController.initBridge(bridgeController: bridgeController)
}

@_cdecl("checkPrecise")
public func checkPrecise() {
    // TODO: call 'checkPrecise' to initiate device geocheck
}

@_cdecl("checkGeneral")
public func checkGeneral() {
    // TODO: call 'checkGeneral' to initiate device geocheck
}

@_cdecl("createProfile") 
public func createProfile() {
    // call 'createProfile' in controller to start collecting Profile data
    bridgeController.createProfile()
}

@_cdecl("sendSomethingToUnity")
public func sendSomethingToUnity(someInt: Int) {
    bridgeController.sendSomethingToUnity(someInt: someInt)
}

@_cdecl("requestLocationConsent")
public func requestLocationConsent() {
    print("🌎")
    // make location consent request using CoreLocation
    let locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
}

/* DELEGATES */
@_cdecl("set_OnInitDelegate")
public func set_OnInitDelegate(delegate: @convention(c) @escaping () -> Void) {
    //bridgeController?.onInit = delegate
    bridgeController.onInit = delegate
}



@_cdecl("set_OnCountryCodeConfirmedDelegate")
public func set_OnCountryCodeConfirmedDelegate(delegate: @convention(c) @escaping (UnsafePointer<CChar>?) -> Void) {
    bridgeController.onCountryCodeConfirmed = delegate
}
@_cdecl("set_OnLocDataSuccessDelegate")
public func set_OnLocDataSuccessDelegate(delegate: @convention(c) @escaping (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void) {
    bridgeController.onLocDataSuccess = delegate
}
@_cdecl("set_OnLocDataFailureDelegate")
public func set_OnLocDataFailureDelegate(delegate: @convention(c) @escaping (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void) {
    bridgeController.onLocDataFailure = delegate
}




@_cdecl("set_OnSomethingDelegate")
public func set_OnSomethingDelegate(delegate: @convention(c) @escaping (UnsafePointer<CChar>?, Int) -> Void) {
    print("🎁 set_OnSomethingDelegate done")
    bridgeController.onSomething = delegate
}
@_cdecl("set_OnConsentTypeConfirmedDelegate")
public func set_OnConsentTypeConfirmedDelegate(delegate: @convention(c) @escaping (UnsafePointer<CChar>?, Int) -> Void) {
    print("🎁 set_OnConsentTypeConfirmedDelegate done")
    bridgeController.onConsentTypeConfirmed = delegate
}
