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
    
    super.init()
  }
  
  /**
   * React native Event Emitter
   */
  override func supportedEvents() -> [String]! {
    return ["callstate"]
  }
  
  override func startObserving() {
    coreDelegate = CoreDelegateStub(
      
      onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
        self.sendEvent(withName: "callstate", body: [
          "message": message,
          "state": state
        ])
      }
    )
    
    core.addDelegate(delegate: coreDelegate)
  }
  
  override func stopObserving() {
    core.removeDelegate(delegate: coreDelegate)
  }
  /**
   * End of React Native Event Emitter
   */
  
  @objc public func register(username: String, password: String, domain: String, _transport: String, resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
    do {
      let transport = switch _transport {
        case "TLS": TransportType.Tls
        case "TCP": TransportType.Tcp
        default: TransportType.Udp
      }
      
      let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: nil, passwd: password, ha1: "", realm: "", domain: domain)
      let accountParams = try core.createAccountParams()
      let identity = try Factory.Instance.createAddress(addr: "sip:\(username)@\(domain)")
      let address = try Factory.Instance.createAddress(addr: "sip:\(domain)")
      
      try accountParams.setIdentityaddress(newValue: identity)
      try address.setTransport(newValue: transport)
      try accountParams.setServeraddress(newValue: address)
      
      accountParams.registerEnabled = true
      account = try core.createAccount(params: accountParams)
      core.addAuthInfo(info: authInfo)
      try core.addAccount(account: account!)
      core.defaultAccount = account
      
    } catch {
      rejecter("REGISTER", error.localizedDescription, error)
    }
  }
  
  @objc public func unregister(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
    if let account = core.defaultAccount {
      let clonedParams = account.params?.clone()
      clonedParams?.registerEnabled = false
      account.params = clonedParams
    }
  }
  
  @objc public func delete() {
    if let account = core.defaultAccount {
      core.removeAccount(account: account)
      core.clearAccounts()
      core.clearAllAuthInfo()
    }
  }
  
  @objc public func accept() {
      try? core.currentCall?.accept()
  }
  
  @objc public func terminate() {
    try? core.currentCall?.terminate()
  }
  
  @objc public func decline() {
    try? core.currentCall?.decline(reason: Reason.Declined)
  }
}
