//
//  LinphoneModule.m
//  linphoneTest
//
//  Created by Mateus Mello on 16/02/24.
//

#import <Foundation/Foundation.h>
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(LinphoneModule, NSObject)
RCT_EXTERN_METHOD(register1:
                  (NSString *) _username
                  password: (NSString *) _password
                  domain: (NSString *) _domain
                   transport: (NSString *) _transport
                   resolver: (RCTPromiseResolveBlock) _resolver
                   rejecter: (RCTPromiseRejectBlock) _rejecter)

RCT_EXPORT_METHOD(call: 
                  (NSString *) address
                  resolve: (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter) {}

RCT_EXTERN_METHOD(unregister:
                  (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter)

RCT_EXPORT_METHOD(deleteAccount) {}
RCT_EXPORT_METHOD(accept) {}
RCT_EXPORT_METHOD(terminate) {}
RCT_EXPORT_METHOD(decline) {}
RCT_EXPORT_METHOD(getAudioDevices:
                  (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter) {}
RCT_EXPORT_METHOD(setAudioDevice:
                  (NSString *) id
                  resolve: (RCTPromiseResolveBlock) resolver
                  reject: (RCTPromiseRejectBlock) rejecter) {}

@end
