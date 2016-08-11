//
//  TWNetworkRequest.h
//  Pods
//
//  Created by Christian Menschel on 16/02/16.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TWNetworkHTTPMethod) {
    TWNetworkHTTPMethodGET = 0,
    TWNetworkHTTPMethodPOST,
    TWNetworkHTTPMethodDELETE,
    TWNetworkHTTPMethodPUT,
    TWNetworkHTTPMethodHEAD,
    TWNetworkHTTPMethodPatch
};

@interface TWNetworkRequest : NSObject

@property (nonatomic) NSURL *URL;
@property (nonatomic) TWNetworkHTTPMethod type;
@property (nonatomic, readonly) NSString *HTTPMethod;
@property (nonatomic) BOOL useCache;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSDictionary *parameters;
@property (nonatomic) NSTimeInterval timeout; // Default 60 seconds

- (NSURLRequest *)URLRequest;

@end
