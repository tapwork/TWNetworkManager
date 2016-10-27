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
    NSString *_postParametersAsString;
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
    request.HTTPMethod = URLRequest.HTTPMethod;
    request.timeout = URLRequest.timeoutInterval;
    request.postParameters = [[NSString alloc] initWithData:URLRequest.HTTPBody encoding:NSUTF8StringEncoding];

    return request;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeout = 60.0;
    }
    return self;
}

#pragma mark - Setter

- (void)setPostParameters:(NSDictionary *)postParameters {
    if (![_postParameters isEqual:postParameters]) {
        _postParameters = postParameters;
        if (!postParameters) {
            _postParametersAsString = nil;
        } else {
            NSMutableString *postString = nil;
            for (NSString *key in postParameters) {
                if (!postString) {
                    [postString appendString:@"&"];
                }
                NSString *value = postParameters[key];
                [postString appendFormat:@"%@=%@", key, value];
            }
            _postParametersAsString = postString;
        }
    }
}

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
    if (_URLRequest.HTTPMethod) {
        return _URLRequest.HTTPMethod;
    }
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

- (NSTimeInterval)timeout
{
    if (_URLRequest) {
        return _URLRequest.timeoutInterval;
    }

    return _timeout;
}

- (NSURL *)URL
{
    if (_URLRequest.URL) {
        return _URLRequest.URL;
    }

    return _URL;
}

- (NSURLRequest *)URLRequest
{
    if (_URLRequest) {
        return _URLRequest;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:self.URL
                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                    timeoutInterval:self.timeout];

    [request setHTTPMethod:self.HTTPMethod];
    if ([self HTTPAuth]) {
        NSString *value = [NSString stringWithFormat:@"Basic %@", [self HTTPAuth]];
        [request setValue:value forHTTPHeaderField:@"Authorization"];
    }
    if (self.postParameters && _postParametersAsString) {
        [request setHTTPBody:[_postParametersAsString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    if (self.HTTPBody) {
        [request setHTTPBody:self.HTTPBody];
    }
    if (_HTTPHeaderFields) {
        for (NSString *key in _HTTPHeaderFields.allKeys) {
            [request setValue:_HTTPHeaderFields[key] forHTTPHeaderField:key];
        }
    }
    
    return request;
}

@end
