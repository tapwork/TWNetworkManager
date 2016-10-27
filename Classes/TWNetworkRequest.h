//
//  TWNetworkRequest.h
//  Pods
//
//  Created by Christian Menschel on 16/02/16.
//
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface TWNetworkRequest : NSObject

@property (nonatomic) NSURL *URL;
@property (nonatomic, readonly) NSMutableURLRequest *URLRequest; // the URLRequest
@property (nonatomic) NSString *HTTPMethod; // Default is GET
@property (nonatomic) BOOL useCache;
@property (nonatomic, nullable) NSString *username;
@property (nonatomic, nullable) NSString *password;
@property (nonatomic, nullable) NSDictionary <NSString*, NSString*> *postParameters;
@property (nonatomic) NSData *HTTPBody; // Overrides postParameters
@property (nonatomic) NSTimeInterval timeout; // Default 60 seconds

+ (TWNetworkRequest *)requestWithURL:(NSURL *)URL; //Creates a standard URL GET Request 
+ (TWNetworkRequest *)requestWithURLRequest:(NSURLRequest *)URLRequest;

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;

@end

NS_ASSUME_NONNULL_END
