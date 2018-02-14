//
//  TWNetworkImageView.h
//  Timecall
//
//  Created by Christian Menschel on 19/06/15.
//
//

@import UIKit;
@class TWNetworkManager;

NS_ASSUME_NONNULL_BEGIN

@interface TWNetworkImageView : UIImageView

@property (nonnull, nonatomic) TWNetworkManager *networkManager; // Default is [TWNetworkManager defaultManager]
@property (nullable, nonatomic) NSURL *URL;

- (void)setURL:(NSURL *)URL animated:(BOOL)animated;
- (void)setImage:(UIImage *_Nullable)image animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
