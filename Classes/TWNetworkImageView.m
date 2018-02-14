//
//  TWNetworkImageView.m
//  Timecall
//
//  Created by Christian Menschel on 19/06/15.
//
//

#import "TWNetworkImageView.h"
#import <TWNetworkManager/TWNetworkManager.h>

static const double kFadeInTime = 0.25;

@implementation TWNetworkImageView

- (TWNetworkManager *)networkManager {
    if (!_networkManager) {
		return [TWNetworkManager defaultManager];
    }
    return _networkManager;
}

- (NSCache *)imageCache {
    return [TWNetworkManager imageCache];
}

- (void)setURL:(NSURL *)URL {
    [self setURL:URL animated:YES];
}

- (void)setURL:(NSURL *)URL animated:(BOOL)animated {
    if (!URL) {
        self.image = nil;

        return;
    }
    _URL = URL;

    __weak typeof(self) weakSelf = self;
    UIImage *image = [self.imageCache objectForKey:URL];
    if (image) {
        self.image = image;
    } else {
        [[self networkManager] imageAtURL:URL
                               completion:^(UIImage *image,
                                            NSString *localFilepath,
                                            BOOL isFromCache,
                                            NSError *error) {
            if ([_URL isEqual:URL]) {
                if (image && URL) {
                    [self.imageCache setObject:image forKey:URL];
                    [weakSelf setImage:image animated:animated];
                }
            }
        }];
    }
}

- (void)setImage:(UIImage *)image {
    [super setImage:image];
    [self.layer setMinificationFilter:kCAFilterTrilinear];

    if (!image) {
        _URL = nil;
    }
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
    if (!animated) {
        self.image = image;
    } else {
        [UIView transitionWithView:self
                          duration:kFadeInTime
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.image = image;
                        }
                        completion:nil];
    }
}

@end
