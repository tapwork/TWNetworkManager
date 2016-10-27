//
//  TWNetworkManager
//
//
//  Created by Christian Menschel on 25.09.13.
//  Copyright (c) 2013 tapwork. All rights reserved.
//

#import "TWNetworkManager.h"
#import <CommonCrypto/CommonHMAC.h>

typedef void(^downloadCompletion)(NSData *data, NSURLResponse *response, NSError *error, NSString *cacheFilePath);

// Make the response writeable
@interface TWNetworkResponse (Private)
@property (nonatomic) NSData *data;
@property (nonatomic) NSURL *requestURL;
@property (nonatomic) NSError *error;
@property (nonatomic) BOOL isFromCache;
@property (nonatomic) NSString *localFilePath;
@property (nonatomic) NSDictionary *headers;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic) NSURLResponse *URLResponse;
@end

static NSString *const kDownloadCachePathname = @"TWDownloadCache";
const char *const kETAGExtAttributeName  = "etag";
const char *const kLastModifiedExtAttributeName  = "lastmodified";
static const double kDownloadTimeout = 20.0;
static const double kETagValidationTimeout = 1.0;
static NSCache *kImageCache = nil;
static dispatch_queue_t kDownloadGCDQueue = nil;

@interface TWNetworkManager () <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, readonly) NSURLSession *urlSession;
@property (nonatomic) NSMutableDictionary *URLCompletionBlocks;
@property (nonatomic) NSMutableDictionary *URLProgressBlocks;
@end

@implementation TWNetworkManager
{
    NSURLSession *_urlSession;
}

static NSUInteger networkFetchingCount = 0;
static void TWBeginNetworkActivity()
{
    networkFetchingCount++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

static void TWEndNetworkActivity()
{
    if (networkFetchingCount > 0) {
        networkFetchingCount--;
        
        if (networkFetchingCount == 0) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
    }
}

#pragma mark - Init & Dealloc

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    static TWNetworkManager *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[[self class] alloc] init];
    });
    
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (!kImageCache) {
            kImageCache = [[NSCache alloc] init];
            [kImageCache setTotalCostLimit:1000];
        }
        if (!kDownloadGCDQueue) {
            kDownloadGCDQueue = dispatch_queue_create("net.tapwork.download_gcd_queue", DISPATCH_QUEUE_CONCURRENT);
        }
        self.URLCompletionBlocks = [NSMutableDictionary dictionary];
        self.URLProgressBlocks = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public methods
- (void)request:(TWNetworkRequest *)request completion:(void(^)(TWNetworkResponse *response))completion
{
    [self request:request completion:completion progress:^(float progress) {}];
}

- (void)request:(TWNetworkRequest *)request
     completion:(void(^)(TWNetworkResponse *response))completion
       progress:(void(^)(float progress))progressBlock
{
    NSParameterAssert(request);
    NSParameterAssert(request.URL);
    
    [self canUseCacheForRequest:request
                     completion:^(BOOL canUseCache) {
                             if (canUseCache) {
                                 // we can grab the data from the cache
                                 // there is no newer version
                                 NSString *filepath = [self cachedFilePathForURL:request.URL];
                                 NSError *error = nil;
                                 NSData *data = [NSData dataWithContentsOfFile:filepath
                                                                       options:NSDataReadingMappedIfSafe
                                                                         error:&error];
                                 
                                 TWNetworkResponse *response = [TWNetworkResponse new];
                                 response.requestURL = request.URL;
                                 response.data = data;
                                 response.error = error;
                                 response.isFromCache = YES;
                                 response.localFilePath = filepath;
                                 if (completion) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         completion(response);
                                     });
                                 }
                             } else {
                                 // We need a fresh request for this URL
                                 NSMutableURLRequest *URLrequest = [[NSMutableURLRequest alloc]
                                                                    initWithURL:request.URL
                                                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                    timeoutInterval:kDownloadTimeout];
                                 [URLrequest setHTTPMethod:request.HTTPMethod];
                                 [self sendRequest:request
                                        completion:^(NSData *data,
                                                     NSURLResponse *URLResponse,
                                                     NSError *error,
                                                     NSString* cacheFilePath) {

                                            TWNetworkResponse *response = [TWNetworkResponse new];
                                     response.requestURL = request.URL;
                                     response.data = data;
                                     response.error = error;
                                     response.localFilePath = cacheFilePath;
                                     response.URLResponse = URLResponse;
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         completion(response);
                                     });
                                 } progress:progressBlock];
                             }
                         }];
}

- (UIImage *)imageAtURL:(NSURL*)url
             completion:(void(^)(UIImage *image,
                                NSString *localFilepath,
                                BOOL isFromCache,
                                NSError *error))completion
{
    NSParameterAssert(url);

    if ([url isKindOfClass:[NSURL class]] &&
        [[[self class] imageCache] objectForKey:url]) {
        // there is already an image in our cache so return this image
        // Download not necessary
        UIImage *image = [[[self class] imageCache] objectForKey:url];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image, nil, YES, nil);
            });
        }

        return image;
    }
    
    TWNetworkRequest *request = [TWNetworkRequest new];
    request.type = TWNetworkHTTPMethodGET;
    request.URL = url;
    request.useCache = YES;
    [self request:request
       completion:^(TWNetworkResponse *response) {
        dispatch_async(kDownloadGCDQueue, ^{
            UIImage *image = nil;
            if (url && response.data) {
                image = [UIImage imageWithData:response.data];
                if (image.size.width < 2 || image.size.height < 2) {
                    image = nil;
                }
                if (image) {
                    [[[self class] imageCache] setObject:image forKey:url];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(image, response.localFilePath, response.isFromCache, response.error);
                }
            });
        });
    }];

    return nil;
}

- (void)cancelAllRequests
{
    [_urlSession invalidateAndCancel];
    _urlSession = nil;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)cancelAllRequestForURL:(NSURL*)url
{
    [self getAllRunningTasks:^(NSArray<NSURLSessionTask *> *tasks) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"originalRequest.URL = %@", url];
        for (NSURLSessionTask *task in [tasks filteredArrayUsingPredicate:predicate]) {
            [task cancel];
        }
    }];
}

- (void)suspend
{
    [self getAllRunningTasks:^(NSArray<NSURLSessionTask *> *tasks) {
        for (NSURLSessionTask *task in tasks) {
            [task cancel];
        }
    }];
}

- (void)resume
{
    [self getAllRunningTasks:^(NSArray<NSURLSessionTask *> *tasks) {
        for (NSURLSessionTask *task in tasks) {
            [task resume];
        }
    }];
}

- (BOOL)reset
{
    [[[self class] imageCache] removeAllObjects];
    NSString *cachePath = [self localCachePath];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error = nil;
    return [fileManager removeItemAtPath:cachePath error:&error];
}

- (BOOL)hasProcessingURLs
{
    return ([self.URLCompletionBlocks count] > 0);
}

- (BOOL)isProcessingURL:(NSURL*)URL
{
    return (self.URLCompletionBlocks[URL] != nil);
}

- (BOOL)hasCachedFileForURL:(NSURL*)URL
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    return [fileManager fileExistsAtPath:[self cachedFilePathForURL:URL]];
}

- (NSString *)cachedFilePathForURL:(NSURL*)url
{
    NSString *md5Filename = [self md5HashForString:[url absoluteString]];
    NSString *fullpath = [[self localCachePath] stringByAppendingPathComponent:md5Filename];
    
    return fullpath;
}

- (NSString *)localCachePath
{
    NSURL *libcache = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    libcache = [libcache URLByAppendingPathComponent:kDownloadCachePathname];
    
    NSFileManager *filemanager = [[NSFileManager alloc] init];
    NSError *error = nil;
    BOOL isDir;
    if (![filemanager fileExistsAtPath:[libcache path] isDirectory:&isDir] ||
        !isDir) {
        [filemanager createDirectoryAtURL:libcache withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return [libcache path];
}

- (BOOL)isNetworkReachable
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    
    return ([reach currentReachabilityStatus] != NotReachable);
}

- (BOOL)isReachableViaWiFi
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    
    return ([reach currentReachabilityStatus] == ReachableViaWiFi);
}

+ (NSCache*)imageCache
{
    return kImageCache;
}

#pragma mark - Private

- (void)canUseCacheForRequest:(TWNetworkRequest *)networkRequest
                completion:(void(^)(BOOL canUseCache))completion
{
    NSParameterAssert(networkRequest.URL);
    NSParameterAssert(completion);
    NSURL *url = networkRequest.URL;
    NSString *cachedFile = [self cachedFilePathForURL:url];
    NSString *eTag = [self eTagAtCachedFilepath:cachedFile];
    NSString *lastModified = [self lastModifiedAtCachedFilepath:cachedFile];
    
    if (!networkRequest.useCache) {
        completion(NO);
    } else if (![self isNetworkReachable] && [self hasCachedFileForURL:url]) {
        completion(YES);
    } else if (![self hasCachedFileForURL:url] || ![self isNetworkReachable] || (!eTag && !lastModified)) {
        completion(NO);
    } else {
        NSMutableURLRequest *request = [[networkRequest URLRequest] mutableCopy];
        if ([eTag length] > 0) {
            [request setValue:eTag forHTTPHeaderField:@"If-None-Match"];
        }
        if ([lastModified length] > 0) {
            [request setValue:lastModified forHTTPHeaderField:@"If-Modified-Since"];
        }
        [request setHTTPMethod:@"HEAD"];
        NSURLSession *session = self.urlSession;
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        
                        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                            NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                            NSDictionary *header = [(NSHTTPURLResponse*)response allHeaderFields];
                            
                            if (statusCode == 304) {  // Not Modified - our cached stuff is fresh enough
                                completion(YES);
                            } else if (statusCode == 301) { // Moved Permanently HTTP Forward
                                NSURL *forwardURL = [NSURL URLWithString:header[@"Location"]];
                                request.URL = forwardURL;
                                [self canUseCacheForRequest:networkRequest completion:completion];
                            } else if (statusCode == 200) {
                                completion(NO);
                            } else if (statusCode > 400 && [self hasCachedFileForURL:url]) {
                                completion(YES);
                            } else {
                                completion(NO);
                            }
                        } else {
                            completion([self hasCachedFileForURL:url]);
                        }
                        
                    }] resume];
    }
}

- (void)sendRequest:(TWNetworkRequest *)request
         completion:(downloadCompletion)completion
           progress:(void(^)(float progress))progressBlock
{
    NSParameterAssert(request);
    NSParameterAssert(request.URL);
    @synchronized (self) {
        NSURL *URL = request.URL;
        NSURLRequest *URLrequest = request.URLRequest;
        TWBeginNetworkActivity();
        NSMutableSet *completionBlocks = nil;
        NSMutableSet *progressBlocks = nil;
        NSURLSessionDownloadTask *downloadTask = nil;
        if (self.URLCompletionBlocks[URL]) {
            completionBlocks = self.URLCompletionBlocks[URL];
        } else {
            completionBlocks = [NSMutableSet set];
            downloadTask = [self.urlSession downloadTaskWithRequest:URLrequest];
        }
        [completionBlocks addObject:completion];

        if (self.URLProgressBlocks[URL]) {
            progressBlocks = self.URLProgressBlocks[URL];
        } else {
            progressBlocks = [NSMutableSet set];
        }
        if (progressBlock) {
            [progressBlocks addObject:progressBlock];
        }

        self.URLCompletionBlocks[URL] = completionBlocks;
        self.URLProgressBlocks[URL] = progressBlocks;

        [downloadTask resume];
    }
}

- (void)getAllRunningTasks:(void (^)(NSArray<NSURLSessionTask *> *tasks))completionHandler; {
    [_urlSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        NSMutableArray *tasks = [NSMutableArray array];
        [tasks addObjectsFromArray:dataTasks];
        [tasks addObjectsFromArray:uploadTasks];
        [tasks addObjectsFromArray:downloadTasks];
        if (completionHandler) {
            completionHandler([tasks copy]);
        }
    }];
}

- (NSString *)md5HashForString:(NSString *)string
{
    const char *cStr = [string UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

- (NSURLSession *)urlSession
{
    if (_urlSession) {
        return _urlSession;
    }

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _urlSession = [NSURLSession sessionWithConfiguration:configuration
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    _urlSession.sessionDescription = @"net.tapwork.twnetworkmanager.nsurlsession";
    
    return _urlSession;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    float progess = (float)totalBytesWritten/totalBytesExpectedToWrite;
    NSURL *URL = downloadTask.originalRequest.URL;
    NSSet *progressBlocks = self.URLProgressBlocks[URL];
    for (void (^block)(float) in progressBlocks) {
        block(progess);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSData *data = [NSData dataWithContentsOfURL:location];
    NSURL *URL = downloadTask.originalRequest.URL;
    NSError *resError = downloadTask.error;
    NSInteger statusCode = 0;
    NSURLResponse *response = downloadTask.response;
    if ([response respondsToSelector:@selector(statusCode)]) {
        statusCode = [(NSHTTPURLResponse*)response statusCode];
    }
    if (statusCode >= 400) {
        NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
        errorUserInfo[@"HTTP statuscode"] = @(statusCode);
        if (downloadTask.error) {
            errorUserInfo[@"underlying error"] = downloadTask.error;
        }
        resError = [NSError errorWithDomain:NSURLErrorDomain
                                       code:statusCode
                                   userInfo:errorUserInfo];
    }

    NSString *filepath = [self cachedFilePathForURL:URL];
    if (data) {
        // for some strange reasons,NSDataWritingAtomic does not override in some cases
        NSFileManager* filemanager = [[NSFileManager alloc] init];
        [filemanager removeItemAtPath:filepath error:nil];
        [data writeToFile:filepath options:NSDataWritingAtomic error:nil];

        NSError *readError = nil;
        data = [NSData dataWithContentsOfFile:filepath
                                      options:NSDataReadingMappedIfSafe
                                        error:&readError];

        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSDictionary *header = [(NSHTTPURLResponse*)response allHeaderFields];
            NSString *etag = header[@"Etag"];
            NSString *lastmodified = header[@"Last-Modified"];
            if (etag) {
                // store the eTag - we use it to check later if the content has been modified
                [self setETag:etag forCachedFilepath:filepath];
            } else if (lastmodified) {
                [self setLastModified:lastmodified forCachedFilepath:filepath];
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        TWEndNetworkActivity();
        @synchronized (self) {
            NSSet *completionBlocks = self.URLCompletionBlocks[URL];
            for (downloadCompletion block in completionBlocks) {
                block(data, response, resError, filepath);
            }
            [self.URLCompletionBlocks removeObjectForKey:URL];
            [self.URLProgressBlocks removeObjectForKey:URL];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        TWEndNetworkActivity();
        @synchronized (self) {
            NSURL *URL = task.originalRequest.URL;
            NSHashTable *completionBlocks = self.URLCompletionBlocks[URL];
            for (downloadCompletion block in completionBlocks) {
                block(nil, task.response, error, nil);
            }
            [self.URLCompletionBlocks removeObjectForKey:URL];
            [self.URLProgressBlocks removeObjectForKey:URL];
        }
    });
}

#pragma mark - Extended File Attributes (eTag & Last Modified)

- (BOOL)setETag:(NSString *)eTag forCachedFilepath:(NSString *)filepath
{
    return [self setExtendedFileAttribute:kETAGExtAttributeName withValue:eTag forCachedFilepath:filepath];
}

- (NSString *)eTagAtCachedFilepath:(NSString *)filepath
{
    return [self extendedFileAttribute:kETAGExtAttributeName cachedFilepath:filepath];
}

- (BOOL)setLastModified:(NSString *)lastModified forCachedFilepath:(NSString *)filepath
{
    return [self setExtendedFileAttribute:kLastModifiedExtAttributeName withValue:lastModified forCachedFilepath:filepath];
}

- (NSString *)lastModifiedAtCachedFilepath:(NSString *)filepath
{
    return [self extendedFileAttribute:kLastModifiedExtAttributeName cachedFilepath:filepath];
}

- (BOOL)setExtendedFileAttribute:(const char *)attribute withValue:(NSString *)value forCachedFilepath:(NSString *)filepath
{
    const char *cfilePath = [filepath fileSystemRepresentation];
    const char *cETag = [value UTF8String];
    
    if (0 != setxattr(cfilePath, attribute, cETag, strlen(cETag), 0, XATTR_NOFOLLOW)) {
        NSLog(@"could not create Extended File Attributes to file %@",filepath);
        return NO;
    }
    
    return YES;
}

- (NSString *)extendedFileAttribute:(const char *)attribute cachedFilepath:(NSString *)filepath
{
    const char *cfilePath = [filepath fileSystemRepresentation];
    NSString *etagString = nil;
    
    // get size of needed buffer
    ssize_t bufferLength = getxattr(cfilePath, attribute, NULL, 0, 0, 0);
    
    if (bufferLength > 0) {
        // make a buffer of sufficient length
        char *buffer = malloc(bufferLength);
        
        getxattr(cfilePath,
                 attribute,
                 buffer,
                 255,
                 0, 0);
        
        etagString = [[NSString alloc] initWithBytes:buffer length:bufferLength encoding:NSUTF8StringEncoding];
        
        // release buffer
        free(buffer);
    }
    
    return etagString;
}

@end

@implementation TWNetworkManager (Deprecated)

- (void)downloadURL:(NSURL *)url
         completion:(void(^)(NSData *_Nullable data,
                             NSString *_Nullable localFilepath,
                             BOOL isFromCache,
                             NSError *_Nullable error))completion __deprecated {
    TWNetworkRequest *request = [TWNetworkRequest new];
    request.URL = url;
    request.useCache = YES;
    [self request:request completion:^(TWNetworkResponse * _Nonnull response) {
        if (completion) {
            completion(response.data, response.localFilePath, response.isFromCache, response.error);
        }
    }];
}

- (void)requestURL:(NSURL*)url
              type:(TWNetworkHTTPMethod)HTTPMethod
        completion:(void(^)(NSData *data,
                            NSString *_Nullable localFilepath,
                            BOOL isFromCache,
                            NSError *_Nullable error))completion __deprecated {
    TWNetworkRequest *request = [TWNetworkRequest new];
    request.URL = url;
    request.useCache = NO;
    request.type = HTTPMethod;
    [self request:request completion:^(TWNetworkResponse * _Nonnull response) {
        if (completion) {
            completion(response.data, response.localFilePath, response.isFromCache, response.error);
        }
    }];
}

@end
