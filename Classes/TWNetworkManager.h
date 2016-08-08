//
//  TWNetworkManager
//
//
//  Created by Christian Menschel on 25.09.13.
//  Copyright (c) 2013 tapwork. All rights reserved.
//

@import UIKit;
@import Foundation;
#include <sys/xattr.h>
#import <Reachability.h>
#import <TWNetworkRequest.h>

@interface TWNetworkManager : NSObject

/// The default network manager's singleton instance
/// TWNetworkManager can be used also as non singleton with [[TWNetworkManager alloc] init]
+ (instancetype)defaultManager;

/// The default image cache with NSURL & UImage (key, value) pair
+ (NSCache *)imageCache;

@property (nonatomic, readonly) BOOL isNetworkReachable;
@property (nonatomic, readonly) BOOL isReachableViaWiFi;

/// Simple async download with disk caching -
/// there will be no download if we are offline or
/// the data on server side hasn't been modified (HTTP 304)
- (void)downloadURL:(NSURL *)url
         completion:(void(^)(NSData *data,
                             NSString *localFilepath,
                             BOOL isFromCache,
                             NSError *error))completion;

/// Image download - uses disk and memory caching - returns the image immediately if the image is in cache
- (UIImage *)imageAtURL:(NSURL *)url
            completion:(void(^)(UIImage *image,
                                NSString *localFilepath,
                                BOOL isFromCache,
                                NSError *error))completion;

/// Request from URL with specific HTTP method - does not use caching
- (void)requestURL:(NSURL*)url
              type:(TWNetworkHTTPMethod)HTTPMethod
        completion:(void(^)(NSData *data,
                            NSString *localFilepath,
                            BOOL isFromCache,
                            NSError *error))completion;

/// Request with NSURLRequest - does not use caching
- (void)request:(NSURLRequest*)request
     completion:(void(^)(NSData *data,
                         NSError *error))completion;

/// Check current process for an URL
/// @param URL The URL to check if it is processing
/// @return YES if URL is currently requested or in download progress
- (BOOL)isProcessingURL:(NSURL *)url;

/// Checks if we already have a cached file on disk for the URL
/// @param URL The URL to check if there is a local representation
/// @return YES If there is local representation
- (BOOL)hasCachedFileForURL:(NSURL *)url;

/// Gives a local representation for the real URL
/// @param URL The URL for the local representation
/// @return A cached filepath for the full URL - nil if nothing is cached
- (NSString *)cachedFilePathForURL:(NSURL *)url;

/// Cancels all outstanding tasks and then invalidates the session object.
- (void)cancelAllRequests;

/// Cancels all tasks for the given URL.
/// @param URL All requests with this URL will be canceled
- (void)cancelAllRequestForURL:(NSURL*)url;

/// Deletes all cached data from disk and removes the images from NSCache
- (BOOL)reset;

@end

