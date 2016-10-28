//
//  TWNetworkRequest.m
//  Pods
//
//  Created by Christian Menschel on 16/02/16.
//
//

#import "TWNetworkRequest.h"

@implementation TWNetworkRequest
{
    NSMutableDictionary *_HTTPHeaderFields;
}

#pragma mark - LifeCycle

+ (TWNetworkRequest *)requestWithURL:(NSURL *)URL
{
    TWNetworkRequest *request = [TWNetworkRequest new];
    request.URL = URL;
    return request;
}

+ (TWNetworkRequest *)requestWithURLRequest:(NSURLRequest *)URLRequest
{
    TWNetworkRequest *request = [TWNetworkRequest new];
    request.URL = URLRequest.URL;
    if (URLRequest.HTTPMethod) {
        request.HTTPMethod = URLRequest.HTTPMethod;
    }
    if (URLRequest.HTTPBody) {
        request.HTTPBody = URLRequest.HTTPBody;
    }
    request.timeout = URLRequest.timeoutInterval;

    return request;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeout = 60.0;
        _HTTPMethod = @"GET";
    }
    return self;
}

#pragma mark - Setter

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field
{
    @synchronized (self) {
        if (!_HTTPHeaderFields) {
            _HTTPHeaderFields = [NSMutableDictionary dictionary];
        }
        _HTTPHeaderFields[field] = value;
    }
}

#pragma mark - Getter

- (NSString *)HTTPAuth
{
    NSString *authStr = nil;
    if (self.username) {
        authStr = self.username;
    }
    if (self.password) {
        authStr = [authStr stringByAppendingFormat:@":%@", self.password];
    }
    if (!authStr) {

        return nil;
    }

    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [authData base64EncodedStringWithOptions:0];

    return authValue;
}

- (NSMutableURLRequest *)URLRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:self.URL
                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                    timeoutInterval:self.timeout];

    [request setHTTPMethod:[self.HTTPMethod uppercaseString]];
    if ([self HTTPAuth]) {
        NSString *value = [NSString stringWithFormat:@"Basic %@", [self HTTPAuth]];
        [request setValue:value forHTTPHeaderField:@"Authorization"];
    }
    if (self.postParameters) {
        [request setHTTPBody:[self.postParameterAsString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if (self.HTTPBody) {
        [request setHTTPBody:self.HTTPBody];
    }
    if (self.HTTPMethod) {
        [request setHTTPMethod:self.HTTPMethod];
    } else {
        [request setHTTPMethod:@"GET"];
    }

    if (_HTTPHeaderFields) {
        for (NSString *key in _HTTPHeaderFields.allKeys) {
            [request setValue:_HTTPHeaderFields[key] forHTTPHeaderField:key];
        }
    }
    
    return request;
}

#pragma mark - Helper

- (NSString *)postParameterAsString {
    NSMutableString *postString = nil;
    for (NSString *key in self.postParameters) {
        if (!postString) {
            [postString appendString:@"&"];
        }
        NSString *value = self.postParameters[key];
        [postString appendFormat:@"%@=%@", key, value];
    }
    return postString;
}

@end
