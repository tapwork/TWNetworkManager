//
//  TWNetworkRequest.h
//  Pods
//
//  Created by Christian Menschel on 16/02/16.
//
//

@import Foundation;

typedef NS_ENUM(NSUInteger, TWNetworkHTTPMethod) {
    TWNetworkHTTPMethodGET = 0,
    TWNetworkHTTPMethodPOST,
    TWNetworkHTTPMethodDELETE,
    TWNetworkHTTPMethodPUT
};

@interface TWNetworkRequest : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) TWNetworkHTTPMethod type;

@end
