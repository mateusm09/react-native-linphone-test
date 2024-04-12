//
//  LinphoneModule.swift
//  linphoneTest
//
//  Created by Mateus Mello on 02/02/24.
//

import Foundation

import linphonesw

@objc(LinphoneModule)
class LinphoneModule: RCTEventEmitter {
  
  var core: Core!
  var account: Account?
  var coreDelegate: CoreDelegate!
  
  private var listenersCount: Int = 0
  
  override init() {
    LoggingService.Instance.logLevel = LogLevel.Debug
    
    try? core = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
    try? core.start()
    
    coreDelegate = CoreDelegateStub(
      
      onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
                  
      }
    )
    
    super.init()
  }
  
  /**
   * React native Event Emitter
   */
  override func supportedEvents() -> [String]! {
    return ["callstate"]
  }
  
  private func _sendEvent(_ eventName: String, _ body: [String: String]) {
    return sendEvent(withName: eventName, body: body)
  }
  
  override func startObserving() {
    core.addDelegate(delegate: coreDelegate)
  }
  
  override func stopObserving() {
    core.removeDelegate(delegate: coreDelegate)
  }
  /**
   * End of React Native Event Emitter
   */
  
  @objc public func register(username: String, password: String, domain: String, transport: String, resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
    
      
    
  }
}
