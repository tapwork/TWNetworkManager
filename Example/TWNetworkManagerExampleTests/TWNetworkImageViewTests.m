//
//  TWNetworkImageViewTests.m
//  TWNetworkManagerExample
//
//  Created by Christian Menschel on 07.08.16.
//  Copyright © 2016 Christian Menschel. All rights reserved.
//

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
    TWNetworkImageView *imageView = [[TWNetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/seb1.png"];;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(imageView, nil);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testResetURLToNewURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testURL"];
    TWNetworkImageView *imageView = [[TWNetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/seb1.png"];;
    imageView.URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/henner.png"];;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(imageView, nil);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}

- (void)testResetURLToNil {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testURL"];
    
    NSURL *URL = [NSURL URLWithString:@"http://www.tapwork.de/api/wp-content/uploads/2014/06/seb1.png"];
    TWNetworkImageView *imageView = [[TWNetworkImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    imageView.URL = URL;
    imageView.URL = nil;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(imageView, nil);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}


@end
