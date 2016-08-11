//
//  TWResponse.h
//  Pods
//
//  Created by Christian Menschel on 11.08.16.
//
//

#import <Foundation/Foundation.h>

@interface TWNetworkResponse : NSObject

@property (nonatomic, readonly, nullable) NSData *data;
@property (nonatomic, readonly, nullable) NSData *error;
@property (nonatomic, readonly) BOOL isFromCache;
@property (nonatomic, readonly, nullable) NSString *localFilePath;
@property (nonatomic, readonly, nullable) NSURL *URL;
@property (nonatomic, readonly, nullable) NSDictionary *headers;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly, nullable) NSURLResponse *URLResponse; // The original response

@end
