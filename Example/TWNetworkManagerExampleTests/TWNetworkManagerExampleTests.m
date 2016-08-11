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
    
    NSURL *url = [NSURL URLWithString:@"http://www.google.de"];
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
    
    [self waitForExpectationsWithTimeout:8.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testImageCache
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testImageCache"];
    
    NSURL *url = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/seb1.png"];
    [[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         UIImage *imageCached = [[TWNetworkManager imageCache] objectForKey:url];
         XCTAssertEqual(image, imageCached);
         
         NSData *cachedData = [[NSData alloc] initWithContentsOfFile:localFilepath];
         XCTAssertTrue([cachedData length] > 0);
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:8.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testIsProcessingURL
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testIsProcessingURL"];
    NSURL *url = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/newslokal_1@2x1.png"];
    [[TWNetworkManager defaultManager] requestURL:url type:TWNetworkHTTPMethodGET completion:^(NSData * _Nonnull data, NSString * _Nullable localFilepath, BOOL isFromCache, NSError * _Nullable error) {
        [expectation fulfill];
    }];
    
    XCTAssertTrue([[TWNetworkManager defaultManager] isProcessingURL:url]);
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
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
    
    [self waitForExpectationsWithTimeout:8.0 handler:^(NSError *error) {
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
    
    [self waitForExpectationsWithTimeout:8.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testCancelAllRequests
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCancelAllRequests"];
    
    NSURL *url = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/seb1.png"];
    [[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         XCTAssertFalse(image);
         [expectation fulfill];
     }];
    
    [[TWNetworkManager defaultManager] cancelAllRequests];
    XCTAssertFalse([[TWNetworkManager defaultManager] isProcessingURL:url]);
    
    [self waitForExpectationsWithTimeout:8.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testReset
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testReset"];
    
    NSURL *url = [NSURL URLWithString:@"http://www.tapwork.de"];
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
