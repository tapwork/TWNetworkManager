//
//  TWNetworkRequest.m
//  Pods
//
//  Created by Christian Menschel on 16/02/16.
//
//

#import "TWNetworkRequest.h"

@implementation TWNetworkRequest

#pragma mark - LifeCycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeout = 60.0;
    }
    return self;
}

#pragma mark - Getter

- (NSString *)HTTPMethod
{
    NSString *HTTPMethod = @"";
    switch (self.type) {
        case TWNetworkHTTPMethodGET:
            HTTPMethod = @"GET";
            break;
        case TWNetworkHTTPMethodPOST:
            HTTPMethod = @"POST";
            break;
        case TWNetworkHTTPMethodDELETE:
            HTTPMethod = @"DELETE";
            break;
        case TWNetworkHTTPMethodPUT:
            HTTPMethod = @"PUT";
            break;
        case TWNetworkHTTPMethodHEAD:
            HTTPMethod = @"HEAD";
            break;
        case TWNetworkHTTPMethodPatch:
            HTTPMethod = @"PATCH";
            break;
    }

    return HTTPMethod;
}

- (NSString *)HTTPAuth {
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
    NSString *authValue = [authData base64Encoding];

    return authValue;
}

- (NSURLRequest *)URLRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:self.URL
                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                    timeoutInterval:self.timeout];

    [request setHTTPMethod:self.HTTPMethod];
    if ([self HTTPAuth]) {
        NSString *value = [NSString stringWithFormat:@"Basic %@", [self HTTPAuth]];
        [request setValue:value forHTTPHeaderField:@"Authorization"];
    }
    
    return request;
}

@end
