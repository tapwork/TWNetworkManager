//
//  TWResponse.m
//  Pods
//
//  Created by Christian Menschel on 11.08.16.
//
//

#import "TWNetworkResponse.h"

@interface TWNetworkResponse ()
@property (nonatomic) NSData *data;
@property (nonatomic) NSURL *requestURL;
@property (nonatomic) NSData *error;
@property (nonatomic) BOOL isFromCache;
@property (nonatomic) NSString *localFilePath;
@property (nonatomic) NSDictionary *headers;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic) NSURLResponse *URLResponse;
@end

@implementation TWNetworkResponse

- (void)setURLResponse:(NSURLResponse *)URLResponse {
    if (![_URLResponse isEqual:URLResponse]) {
        _URLResponse = URLResponse;
        if (!URLResponse) {
            _statusCode = NSNotFound;
            _headers = nil;
        } else {
            if ([URLResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)URLResponse;
                _statusCode = HTTPURLResponse.statusCode;
                _headers = HTTPURLResponse.allHeaderFields;
            }
        }
    }
}

@end
