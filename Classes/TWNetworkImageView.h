//
//  TWNetworkImageView.h
//  Timecall
//
//  Created by Christian Menschel on 19/06/15.
//
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface TWNetworkImageView : UIImageView

@property (nullable, nonatomic) NSURL *URL;

- (void)setImage:(UIImage *_Nullable)image animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
