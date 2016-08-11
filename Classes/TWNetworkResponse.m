//
//  TWResponse.m
//  Pods
//
//  Created by Christian Menschel on 11.08.16.
//
//

#import "TWNetworkResponse.h"

@interface TWNetworkResponse ()
@property (nonatomic) NSData *data;
@property (nonatomic) NSData *error;
@property (nonatomic) BOOL isFromCache;
@property (nonatomic) NSString *localFilePath;
@property (nonatomic) NSURL *requestURL;
@property (nonatomic) NSURL *responseURL;
@end

@implementation TWNetworkResponse

@end
