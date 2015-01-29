//
//  TWNetworkManagerExampleTests.m
//  TWNetworkManagerExampleTests
//
//  Created by Christian Menschel on 27/01/15.
//  Copyright (c) 2015 Christian Menschel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <TWNetworkManager/TWNetworkManager.h>


@interface TWNetworkManagerExampleTests : XCTestCase
@end

@implementation TWNetworkManagerExampleTests

- (void)testRequestHTML
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRequestHTML"];
    
    NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/10/10/"];
    [[TWNetworkManager defaultManager]
     requestURL:url
     type:TWNetworkHTTPMethodGET completion:^(NSData *data, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         XCTAssertTrue(data);
         XCTAssertTrue(localFilepath);
         XCTAssertFalse(isFromCache);
         XCTAssertFalse(error);
         
         [[TWNetworkManager defaultManager]
          requestURL:url
          type:TWNetworkHTTPMethodGET completion:^(NSData *data2, NSString *localFilepath2, BOOL isFromCache2, NSError *error2) {
              XCTAssertNotEqual(data,data2);
              
              [expectation fulfill];
          }];
     }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testImageCache
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testImageCache"];
    
    NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/15/15/"];
    [[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         UIImage *imageCached = [[TWNetworkManager imageCache] objectForKey:url];
         XCTAssertEqual(image, imageCached);
         
         NSData *cachedData = [[NSData alloc] initWithContentsOfFile:localFilepath];
         XCTAssertTrue([cachedData length] > 0);
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testIsProcessingURL
{
    NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/25/25/"];
    [[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
     }];
    
    XCTAssertTrue([[TWNetworkManager defaultManager] isProcessingURL:url]);
}

- (void)testEtagAndLastModified
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testEtagAndLastModified"];
    
    NSURL *url = [NSURL URLWithString:@"http://www.cmenschel.de/wp-content/uploads/2014/09/demo.png"];
    [[TWNetworkManager defaultManager]
     downloadURL:url
     completion:^(NSData *data, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         [[TWNetworkManager defaultManager]
          downloadURL:url
          completion:^(NSData *data2, NSString *localFilepath2, BOOL isFromCache2, NSError *error2) {
              
              XCTAssertEqual([data length], [data2 length]);
              XCTAssertTrue(isFromCache2);
              if (![localFilepath isEqualToString:localFilepath2]) {
                  XCTFail(@"must be same string");
              }
              
              [expectation fulfill];
          }];
     }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testhasCachedFileForURL
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testhasCachedFileForURL"];
    
    NSURL *url = [NSURL URLWithString:@"http://www.cmenschel.de/wp-content/uploads/2014/06/debug_view2.png"];
    [[TWNetworkManager defaultManager]
     downloadURL:url
     completion:^(NSData *data, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         XCTAssertTrue(data);
         XCTAssertTrue([[TWNetworkManager defaultManager] hasCachedFileForURL:url]);
         NSData *cachedData = [[NSData alloc] initWithContentsOfFile:localFilepath];
         XCTAssertEqual([cachedData length], [data length]);
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testCancelAllRequests
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCancelAllRequests"];
    
    NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/40/40/"];
    [[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         XCTAssertFalse(image);
         [expectation fulfill];
     }];
    
    [[TWNetworkManager defaultManager] cancelAllRequests];
    XCTAssertFalse([[TWNetworkManager defaultManager] isProcessingURL:url]);
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testReset
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testReset"];
    
    NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/55/55/"];
    [[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         [[TWNetworkManager defaultManager] reset];
         UIImage *imageCached = [[TWNetworkManager imageCache] objectForKey:url];
         NSString *filePath = [[TWNetworkManager defaultManager] cachedFilePathForURL:url];
         XCTAssertFalse([[TWNetworkManager defaultManager] hasCachedFileForURL:url]);
         XCTAssertFalse(imageCached);
         NSData *cachedData = [[NSData alloc] initWithContentsOfFile:filePath];
         XCTAssertFalse(cachedData);
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

@end
