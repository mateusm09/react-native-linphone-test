//
//  LinphoneModule.swift
//  linphoneTest
//
//  Created by Mateus Mello on 02/02/24.
//

import Foundation

import linphonesw
import os

@available(iOS 14.0, *)
@objc(LinphoneModule)
class LinphoneModule: RCTEventEmitter {
  
  var core: Core!
  var account: Account?
  var coreDelegate: CoreDelegate!
  
  private var listenersCount: Int = 0
  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")
  
  override init() {
    LoggingService.Instance.logLevel = LogLevel.Debug
    
    try? core = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
    try? core.start()
    
    super.init()
  }
  
  override class func requiresMainQueueSetup() -> Bool {
    return false
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
          "state": String(describing: state)
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
  
  @objc
  public func register(_ _username: String, password _password: String,domain _domain: String,transport _transport: String, resolver _resolver: @escaping RCTPromiseResolveBlock, rejecter _rejecter: @escaping RCTPromiseRejectBlock) {
    
    let registrationDelegate = AccountDelegateStub(onRegistrationStateChanged: {
      (account: Account, state: RegistrationState, message: String) in
      if (state != .Ok && state != .Progress) {
        _rejecter(String(describing: state), message, NSError(domain: "register", code: state.rawValue))
      } else if (state == .Ok) {
        _resolver("Registration successful")
      }
    })
    
    do {
      let transport = switch _transport {
        case "Tls": TransportType.Tls
        case "Tcp": TransportType.Tcp
        default: TransportType.Udp
      }
      
      let authInfo = try Factory.Instance.createAuthInfo(username: _username, userid: nil, passwd: _password, ha1: "", realm: "", domain: _domain)
      let accountParams = try core.createAccountParams()
      let identity = try Factory.Instance.createAddress(addr: "sip:\(_username)@\(_domain)")
      let address = try Factory.Instance.createAddress(addr: "sip:\(_domain)")
      
      try accountParams.setIdentityaddress(newValue: identity)
      try address.setTransport(newValue: transport)
      try accountParams.setServeraddress(newValue: address)
      
      accountParams.registerEnabled = true
      account = try core.createAccount(params: accountParams)
      core.addAuthInfo(info: authInfo)
      try core.addAccount(account: account!)
      core.defaultAccount = account
            
      account?.addDelegate(delegate: registrationDelegate)
    } catch {
      logger.error("registration error \(error.localizedDescription)")
      account?.removeDelegate(delegate: registrationDelegate)
      _rejecter("register", error.localizedDescription, error)
    }
  }
  
  @objc public func unregister(_ resolver: @escaping RCTPromiseResolveBlock, reject rejecter: @escaping RCTPromiseRejectBlock) {
    if let account = core.defaultAccount {
      let clonedParams = account.params?.clone()
      clonedParams?.registerEnabled = false
      account.params = clonedParams
      
      let registrationDelegate = AccountDelegateStub(onRegistrationStateChanged: {
        (account: Account, state: RegistrationState, message: String) in
        if (state == .Ok) {
            resolver("Unregistration successful")
        } else {
          rejecter(String(describing: state), message, NSError(domain: "unregister", code: state.rawValue))
        }
      })
      
      account.addDelegate(delegate: registrationDelegate)
    }
  }
  
  @objc public func deleteAccount() {
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
  
  @objc(call: resolve: reject:)
  public func call(_ address: String, resolve resolver: RCTPromiseResolveBlock, reject rejecter: RCTPromiseRejectBlock) {
    logger.info("Calling \(address)")
    
    do {
      let remoteAddress = try Factory.Instance.createAddress(addr: address)
      let callParams = try core.createCallParams(call: nil)
      
      callParams.mediaEncryption = MediaEncryption.None
      let _ = core.inviteAddressWithParams(addr: remoteAddress, params: callParams)
      
      resolver(true)
    } catch {
      logger.error("Error Calling: \(error.localizedDescription)")
      rejecter("call-creation", error.localizedDescription, error)
    }
  }
  
  @objc public func getAudioDevices(_ resolver: RCTPromiseResolveBlock, reject rejecter: RCTPromiseRejectBlock) {
    var values: [[String:String]] = []
    
    for device in core.audioDevices {
      
      let capabilities = {
        switch (device.capabilities) {
        case .CapabilityPlay:
          return "CapabilityPlay"
        case .CapabilityRecord:
          return "CapabilityRecord"
        default:
          return "CapabilityAll"
        }
      }()
      
      let mappedDevice: [String:String] = [
        "name": device.deviceName,
        "driverName": device.driverName,
        "id": device.id,
        "type": String(describing: device.type),
        "capabilities": capabilities
      ]
      
      values.append(mappedDevice)
    }
    
    let returned: [String: Any] = [
      "devices": values,
      "current": core.currentCall?.outputAudioDevice?.id ?? ""
    ]
    resolver(returned)
  }
  
  @objc public func setAudioDevice(_ id: String, resolve resolver: RCTPromiseResolveBlock, reject rejecter: RCTPromiseRejectBlock) {
    if (core.currentCall == nil) {
      rejecter("no-call", "no current call", NSError(domain: "call", code: 1))
    }
    
    if let newDevice = core.audioDevices.first(where: { (i) in i.id == id }) {
      if (newDevice.id == core.currentCall?.outputAudioDevice?.id) {
        return
      }
      
      core.currentCall?.outputAudioDevice = newDevice
    } else {
      rejecter("no-device", "No device with \(id) found", NSError(domain: "no-device", code: 0))
    }
  }
}
