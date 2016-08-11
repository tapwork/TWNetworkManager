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
#import "TWNetworkRequest.h"
#import "TWNetworkResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface TWNetworkManager : NSObject

/// The default network manager's singleton instance
/// TWNetworkManager can be used also as non singleton with [[TWNetworkManager alloc] init]
+ (instancetype)defaultManager;

/// The default image cache with NSURL & UImage (key, value) pair
+ (NSCache *)imageCache;

@property (nonatomic, readonly) BOOL isNetworkReachable;
@property (nonatomic, readonly) BOOL isReachableViaWiFi;

/// Request with a custom configurable TWRequest object
- (void)request:(TWNetworkRequest *)request completion:(void(^)(TWNetworkResponse *response))completion;

/// Image download - uses disk and memory caching - returns the image immediately if the image is in cache
- (UIImage *)imageAtURL:(NSURL *)url
             completion:(void(^)(UIImage *_Nullable image,
                                 NSString *_Nullable localFilepath,
                                 BOOL isFromCache,
                                 NSError *_Nullable error))completion;

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
- (NSString *_Nullable)cachedFilePathForURL:(NSURL *)url;

/// Cancels all outstanding tasks and then invalidates the session object.
- (void)cancelAllRequests;

/// Cancels all tasks for the given URL.
/// @param URL All requests with this URL will be canceled
- (void)cancelAllRequestForURL:(NSURL *)url;

/// Deletes all cached data from disk and removes the images from NSCache
- (BOOL)reset;

- (NSString *)localCachePath;

@end

@interface TWNetworkManager (Deprecated)

- (void)downloadURL:(NSURL *)url
         completion:(void(^)(NSData *_Nullable data,
                             NSString *_Nullable localFilepath,
                             BOOL isFromCache,
                             NSError *_Nullable error))completion __deprecated;

- (void)requestURL:(NSURL*)url
              type:(TWNetworkHTTPMethod)HTTPMethod
        completion:(void(^)(NSData *data,
                            NSString *_Nullable localFilepath,
                            BOOL isFromCache,
                            NSError *_Nullable error))completion __deprecated;

@end

NS_ASSUME_NONNULL_END
