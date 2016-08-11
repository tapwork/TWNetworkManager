//
//  TWNetworkRequest.h
//  Pods
//
//  Created by Christian Menschel on 16/02/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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
@property (nonatomic, nullable) NSURLRequest *URLRequest; // Set a custom request to override all properties
@property (nonatomic) TWNetworkHTTPMethod type;
@property (nonatomic, readonly) NSString *HTTPMethod; // Default is GET
@property (nonatomic) BOOL useCache;
@property (nonatomic, nullable) NSString *username;
@property (nonatomic, nullable) NSString *password;
@property (nonatomic, nullable) NSDictionary <NSString*, NSString*> *postParameters;
@property (nonatomic) NSTimeInterval timeout; // Default 60 seconds

@end

NS_ASSUME_NONNULL_END
