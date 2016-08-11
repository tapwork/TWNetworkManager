//
//  TWResponse.h
//  Pods
//
//  Created by Christian Menschel on 11.08.16.
//
//

#import <Foundation/Foundation.h>

@interface TWNetworkResponse : NSObject

@property (nonatomic, readonly, nullable) NSData *data;
@property (nonatomic, readonly, nullable) NSData *error;
@property (nonatomic, readonly) BOOL isFromCache;
@property (nonatomic, readonly, nullable) NSString *localFilePath;
@property (nonatomic, readonly, nullable) NSURL *requestURL;
@property (nonatomic, readonly, nullable) NSURL *responseURL;

@end
