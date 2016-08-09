//
//  TWNetworkImageViewTests.m
//  TWNetworkManagerExample
//
//  Created by Christian Menschel on 09.08.16.
//  Copyright © 2016 Christian Menschel. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "TWNetworkImageView.h"

@interface TWNetworkImageViewTests : FBSnapshotTestCase

@end

@implementation TWNetworkImageViewTests

- (void)setUp {
    [super setUp];
    self.recordMode = NO;
}

- (void)testURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testURL"];
    
    TWNetworkImageView *imageView = [[TWNetworkImageView alloc] init];
    imageView.URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/christian.png"];
    imageView.frame = CGRectMake(0, 0, 320, 240);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(imageView, nil);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testResetURLToNil {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testResetURLToNil"];
    
    TWNetworkImageView *imageView = [[TWNetworkImageView alloc] init];
    imageView.URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/christian.png"];
    imageView.frame = CGRectMake(0, 0, 320, 240);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.URL = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(imageView, nil);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testResetURLToNewURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testResetURLToNewURL"];
    
    TWNetworkImageView *imageView = [[TWNetworkImageView alloc] init];
    imageView.URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/christian.png"];
    imageView.frame = CGRectMake(0, 0, 320, 240);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/henner.png"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(imageView, nil);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}


@end
