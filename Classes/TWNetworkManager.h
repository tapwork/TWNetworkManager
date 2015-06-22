//
//  TWNetworkManager
//
//
//  Created by Christian Menschel on 25.09.13.
//  Copyright (c) 2013 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/xattr.h>
#import "Reachability.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          TWNetworkRequest Class
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

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



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          TWNetworkManager Class
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface TWNetworkManager : NSObject

// The default network manager's singleton instance
+ (instancetype)defaultManager;

+ (NSCache *)imageCache;

@property (nonatomic, readonly) BOOL isNetworkReachable;
@property (nonatomic, readonly) BOOL isReachableViaWiFi;

// Simple async download with disk caching -
// there will be no download if we are offline or
// the data on server side hasn't been modified (HTTP 304)
- (void)downloadURL:(NSURL *)url
         completion:(void(^)(NSData *data,
                             NSString *localFilepath,
                             BOOL isFromCache,
                             NSError *error))completion;

// Image download - uses disk and memory caching - returns the image immediately if the image is in cache
- (UIImage *)imageAtURL:(NSURL *)url
            completion:(void(^)(UIImage *image,
                                NSString *localFilepath,
                                BOOL isFromCache,
                                NSError *error))completion;

// Request from URL with specific HTTP method - does not use caching
- (void)requestURL:(NSURL*)url
              type:(TWNetworkHTTPMethod)HTTPMethod
        completion:(void(^)(NSData *data,
                            NSString *localFilepath,
                            BOOL isFromCache,
                            NSError *error))completion;

// Request with NSURLRequest - does not use caching
- (void)request:(NSURLRequest*)request
     completion:(void(^)(NSData *data,
                         NSError *error))completion;

// returns YES if URL is currently requested or in download progress
- (BOOL)isProcessingURL:(NSURL *)url;

// checks if we already have a cached file on disk for the URL
- (BOOL)hasCachedFileForURL:(NSURL *)url;

// returns a cached filepath for the full URL - nil if nothing is cached
- (NSString *)cachedFilePathForURL:(NSURL *)url;

// Cancels all outstanding tasks and then invalidates the session object.
- (void)cancelAllRequests;

- (void)cancelAllRequestForURL:(NSURL*)url;

// Deletes all cached data from disk and removes the images from NSCache
- (BOOL)reset;

@end

