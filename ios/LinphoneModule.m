//
//  LinphoneModule.m
//  linphoneTest
//
//  Created by Mateus Mello on 16/02/24.
//

#import <Foundation/Foundation.h>
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(LinphoneModule, NSObject)
RCT_EXTERN_METHOD(register:
                  (NSString *) username
                  (NSString *) password
                  (NSString *) domain
                  (NSString *) _transport)
@end
