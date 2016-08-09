//
//  TWNetworkImageView.h
//  Timecall
//
//  Created by Christian Menschel on 19/06/15.
//
//

#import <UIKit/UIKit.h>

@interface TWNetworkImageView : UIImageView

@property (nonatomic) NSURL *URL;

- (void)setImage:(UIImage *)image animated:(BOOL)animated;

@end
