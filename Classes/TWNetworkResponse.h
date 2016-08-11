//
//  TWResponse.h
//  Pods
//
//  Created by Christian Menschel on 11.08.16.
//
//

#import <Foundation/Foundation.h>

@interface TWNetworkResponse : NSObject

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSData *error;
@property (nonatomic, readonly) NSData *isFromCache;
@property (nonatomic, readonly) NSString *localFilePath;
@property (nonatomic, readonly) NSURL *requestURL;
@property (nonatomic, readonly) NSURL *responseURL;

@end
