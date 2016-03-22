# TWNetworkManager
[![Build Status](https://api.travis-ci.org/tapwork/TWNetworkManager.svg?style=flat)](https://travis-ci.org/tapwork/TWNetworkManager)
[![CocoaPods Version](http://img.shields.io/cocoapods/v/TWNetworkManager.svg?style=flat)](https://github.com/tapwork/TWNetworkManager/blob/master/TWNetworkManager.podspec)
[![](http://img.shields.io/cocoapods/l/TWNetworkManager.svg?style=flat)](https://github.com/tapwork/TWNetworkManager/blob/master/LICENSE.md)
[![CocoaPods Platform](http://img.shields.io/cocoapods/p/TWNetworkManager.svg?style=flat)]()

#####TWNetworkManager is a lightweight Objective-C network resource download library with caching support based on NSURLSession.

#### Features
* Download files with disk cache support (HTTP eTag and Last-Modified)
* UIImage fetcher with memory and disk caching
* Request resources without caching
* HTTP method support: POST, GET, DELETE, PUT
* Reachability

# Why
TWNetworkManager is a wrapper for NSURLSession with some extras and convenience methods. The purpose is NOT to replace AFNetworking. I just wanted to have a simple NSURLSession wrapper with caching support that everyone else can adapt easily.

# Installation
TWNetworkManager requires iOS 7 or later.
### CocoaPods

Just add the TWNetworkManager to your `Podfile`.
```objc
pod 'TWNetworkManager'
```
and run `pod install` afterwards.

### Without CocoaPods
Download the repository into your project via git or just as zip.
Drag the `Classes` folder with the 4 files (`Reachability.h/m` & `TWNetworkManager.h/m`) folder into your Xcode project.

# How to use it
Example are still in Objective C. Sure, Swift works as well.
Make sure to import the header file
```objc
#import <TWNetworkManager/TWNetworkManager.h>
```
The `defaultManager` is the standard singleton instance. But TWNetworkManager can also be used as non singleton  with `[[TWNetworkManager alloc] init]`.

### Download
This method uses disk caching with HTTP `eTag` and `Last-Modified`.
```objc
NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/700/300/"];
[[TWNetworkManager defaultManager]
          downloadURL:url
          completion:^(NSData *data,
                       NSString *localFilepath,
                       BOOL isFromCache,
                       NSError *error) {

              // Do something with the data

          }];
```

### Image download
It's a more convient method to get an UIImage.
It uses memory and also disk caching with HTTP `eTag` and `Last-Modified`.
```objc
NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/700/300/"];
[[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image,
                  NSString *localFilepath,
                  BOOL isFromCache,
                  NSError *error) {

         self.imageView.image = image;
     }];
```

### Request
This starts the download without any disk caching.
As parameter you can pass the HTTP methods:<br>
GET : `TWNetworkHTTPMethodGET`<br>
POST : `TWNetworkHTTPMethodPOST`<br>
PUT : `TWNetworkHTTPMethodPUT`<br>
DELETE : `TWNetworkHTTPMethodDELETE`<br>

```objc
NSURL *url = [NSURL URLWithString:@"http://whatthecommit.com"];
[[TWNetworkManager defaultManager]
     requestURL:url
     type:TWNetworkHTTPMethodGET
     completion:^(NSData *data,
                  NSString *localFilepath,
                  BOOL isFromCache,
                  NSError *error) {

         NSString *html = [[NSString alloc]
                              initWithData:data
                              encoding:NSASCIIStringEncoding];

     }];
```

### More method calls
This resets the memory cache and deletes all cached data on disk
```objc
- (BOOL)reset;
```

This cancels all running requests
```objc
- (BOOL)cancelAllRequests;
```

Returns a path of a cached file for a given NSURL
```objc
- (NSString *)cachedFilePathForURL:(NSURL *)url;
```

Returns YES if there is a cached file on disk for the given NSURL
```objc
- (BOOL)hasCachedFileForURL:(NSURL *)url;
```

Returns YES if the given NSURL is currently being progressed
```objc
- (BOOL)isProcessingURL:(NSURL *)url;
```

Good old Reachability
```objc
@property (nonatomic, readonly) BOOL isNetworkReachable;
@property (nonatomic, readonly) BOOL isReachableViaWiFi;
```

# Example project
TWNetworkManager comes with an example project and some unit tests. Just open `Example/TWNetworkManagerExample.xcworkspace`

# Todo
* ~~Test with Swift~~ (WORKS)
* OS X Support

# Other Frameworks
* [AFNetworking](https://github.com/AFNetworking/AFNetworking) by [Mattt Thompson](https://twitter.com/mattt) which is probably the most used Objective-C 3rd party library.


# Author
* [Christian Menschel](http://github.com/tapwork) ([@cmenschel](https://twitter.com/cmenschel))


# License
[MIT](LICENSE.md)
