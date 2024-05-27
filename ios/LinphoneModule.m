//
//  LinphoneModule.m
//  linphoneTest
//
//  Created by Mateus Mello on 16/02/24.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import "React/RCTEventEmitter.h"

@interface RCT_EXTERN_MODULE(LinphoneModule, RCTEventEmitter)
RCT_EXTERN_METHOD(register: (NSString *) _username
                             password: (NSString *) _password
                             domain: (NSString *) _domain
                             transport: (NSString *) _transport
                             resolver: (RCTPromiseResolveBlock) _resolver
                             rejecter: (RCTPromiseRejectBlock) _rejecter
                            )

RCT_EXTERN_METHOD(call: (NSString *) address
                  resolve: (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter)

RCT_EXTERN_METHOD(unregister: (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter)

RCT_EXTERN_METHOD(deleteAccount)
RCT_EXTERN_METHOD(accept)
RCT_EXTERN_METHOD(terminate)
RCT_EXTERN_METHOD(decline)
RCT_EXTERN_METHOD(getAudioDevices: (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter)

RCT_EXTERN_METHOD(setAudioDevice: (NSString *) id
                  resolve: (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter)

@end
