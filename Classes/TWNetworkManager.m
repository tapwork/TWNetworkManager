//
//  TWNetworkManager
//
//
//  Created by Christian Menschel on 25.09.13.
//  Copyright (c) 2013 tapwork. All rights reserved.
//

#import "TWNetworkManager.h"
#import <CommonCrypto/CommonHMAC.h>

// Make the response writeable
@interface TWNetworkResponse (Private)
@property (nonatomic) NSData *data;
@property (nonatomic) NSData *error;
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

@interface TWNetworkManager ()

@property (nonatomic, readonly) NSURLSession *urlSession;
@property (nonatomic, readonly) NSSet *runningURLRequests;

@end

@implementation TWNetworkManager
{
    NSURLSession *_urlSession;
    NSSet *_runningURLRequests;
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
    }
    return self;
}

#pragma mark - Public methods

- (void)request:(TWNetworkRequest *)request completion:(void(^)(TWNetworkResponse *response))completion
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
                                 [self sendRequest:request completion:^(NSData *data,
                                                                        NSURLResponse *URLResponse,
                                                                        NSError *error,
                                                                        NSString* cacheFilePath) {
                                     
                                     TWNetworkResponse *response = [TWNetworkResponse new];
                                     response.data = data;
                                     response.error = error;
                                     response.localFilePath = cacheFilePath;
                                     response.URLResponse = URLResponse;
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         completion(response);
                                     });
                                 }];
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
    _runningURLRequests = nil;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)cancelAllRequestForURL:(NSURL*)url
{
    [_urlSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {

        NSInteger capacity = [dataTasks count] + [uploadTasks count] + [downloadTasks count];
        NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:capacity];
        [tasks addObjectsFromArray:dataTasks];
        [tasks addObjectsFromArray:uploadTasks];
        [tasks addObjectsFromArray:downloadTasks];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"originalRequest.URL = %@", url];
        [tasks filterUsingPredicate:predicate];
        for (NSURLSessionTask *task in tasks) {
            [task cancel];
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

- (BOOL)isProcessingURL:(NSURL*)url
{
    return ([self.runningURLRequests containsObject:url]);
}

- (BOOL)hasCachedFileForURL:(NSURL*)url
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    return [fileManager fileExistsAtPath:[self cachedFilePathForURL:url]];
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

- (void)canUseCacheForRequest:(TWNetworkRequest *)request
                completion:(void(^)(BOOL canUseCache))completion
{
    NSParameterAssert(request.URL);
    NSParameterAssert(completion);
    NSURL *url = request.URL;
    NSString *cachedFile = [self cachedFilePathForURL:url];
    NSString *eTag = [self eTagAtCachedFilepath:cachedFile];
    NSString *lastModified = [self lastModifiedAtCachedFilepath:cachedFile];
    
    if (!request.useCache) {
        completion(NO);
    } else if (![self isNetworkReachable] && [self hasCachedFileForURL:url]) {
        completion(YES);
    } else if (![self hasCachedFileForURL:url] || ![self isNetworkReachable] || (!eTag && !lastModified)) {
        completion(NO);
    } else {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                        initWithURL:url
                                        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                        timeoutInterval:kETagValidationTimeout];
        if ([eTag length] > 0) {
            [request setValue:eTag forHTTPHeaderField:@"If-None-Match"];
        }
        if ([lastModified length] > 0) {
            [request setValue:lastModified forHTTPHeaderField:@"If-Modified-Since"];
        }
        [request setHTTPMethod:@"HEAD"];
        __weak __typeof(self) weakself = self;
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
                                [self canUseCacheForRequest:request completion:completion];
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
         completion:(void(^)(NSData *data,
                             NSURLResponse *response,
                             NSError *error,
                             NSString *cacheFilePath))completion
{
    NSParameterAssert(request);
    NSParameterAssert(request.URL);
    
    NSURL *url = request.URL;
    NSURLRequest *URLrequest = request.URLRequest;
    TWBeginNetworkActivity();
    [self addRequestedURL:url];
    NSURLSession *session = self.urlSession;
    [[session dataTaskWithRequest:URLrequest
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *connectionError) {
                    
                    TWEndNetworkActivity();
                    
                    NSError *resError = connectionError;
                    NSInteger statusCode = 0;
                    if ([response respondsToSelector:@selector(statusCode)]) {
                        statusCode = [(NSHTTPURLResponse*)response statusCode];
                    }
                    if (statusCode >= 400) {
                        NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
                        errorUserInfo[@"HTTP statuscode"] = @(statusCode);
                        if (connectionError) {
                            errorUserInfo[@"underlying error"] = connectionError;
                        }
                        resError = [NSError errorWithDomain:NSURLErrorDomain
                                                       code:statusCode
                                                   userInfo:errorUserInfo];
                    }
                    
                    NSString *filepath = [self cachedFilePathForURL:url];
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
                    [self removeRequestedURL:url];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(data, response, resError, filepath);
                        }
                    });
                }] resume];
}

- (void)addRequestedURL:(NSURL*)url
{
    @synchronized(self) {
        if (url) {
            NSMutableSet *requests = [self.runningURLRequests mutableCopy];
            [requests addObject:url];
            _runningURLRequests = [requests copy];
        }
    }
}

- (void)removeRequestedURL:(NSURL*)url
{
    @synchronized(self ) {
        NSMutableSet *requests = [self.runningURLRequests mutableCopy];
        if (url && [requests containsObject:url]) {
            [requests removeObject:url];
            _runningURLRequests = [requests copy];
        }
    }
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

- (NSSet *)runningURLRequests
{
    if (!_runningURLRequests) {
       _runningURLRequests = [[NSSet alloc] init];
    }
    return _runningURLRequests;
}

- (NSURLSession *)urlSession
{
    if (_urlSession) {
        return _urlSession;
    }
    
    _urlSession = [NSURLSession sessionWithConfiguration:
                   [NSURLSessionConfiguration defaultSessionConfiguration]];
    _urlSession.sessionDescription = @"net.tapwork.twnetworkmanager.nsurlsession";
    
    return _urlSession;
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
