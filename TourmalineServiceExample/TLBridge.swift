//
//  TLBridge.swift
//  TourmalineServiceExample
//
//  Created by Brian Dennis Vega Hidalgo on 28-10-19.
//  Copyright © 2019 Brian Dennis Vega Hidalgo. All rights reserved.
//

import Foundation

@objc(TLBridge)class TLBridge: NSObject {
  
  @objc static var isTracking = false
 // @objc static var tlkit:TLKitManager = TLKitManager();
  
  @objc func onDuty() {
    TLBridge.isTracking = true
    print("TSBridge is tracking")
//    TLBridge.tlkit.startDriveMonitoring();
  }
  
  @objc func offDuty() {
//    TLBridge.isTracking = false;
    print("TSBridge is not tracking");
//    TLBridge.tlkit.stopDriveMonitoring();
  }
  
  @objc func startTLKit(_ username: String?) {
//    var arbitraryReturnVal:NSArray = ["Starting TLKIT..."];
//      TLBridge.tlkit.begin(username);
//      TLBridge.tlkit.startTLKit();

  }
  
  @objc func stopTLKit() {
    DispatchQueue.main.async {
//      TLBridge.tlkit.stopTLKit();
    }
  }
  
  @objc static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  
}
