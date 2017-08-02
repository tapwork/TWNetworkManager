//
//  ViewController.m
//  TWNetworkManagerExample
//
//  Created by Christian Menschel on 27/01/15.
//  Copyright (c) 2015 Christian Menschel. All rights reserved.
//

#import "ViewController.h"
@import TWNetworkManager;

static const CGSize kButtonSize = {120.0,30};

@interface ViewController ()

@property (nonatomic) UIButton *button1;
@property (nonatomic) UIButton *button2;
@property (nonatomic) UIButton *button3;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIWebView *webiew;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    self.webiew = [[UIWebView alloc] init];
    self.webiew.scalesPageToFit = YES;
    [self.view addSubview:self.webiew];
    
    self.button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.button1 setTitle:@"Download image" forState:UIControlStateNormal];
    [self.button1 addTarget:self action:@selector(downloadImageAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button1];
    
    self.button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.button2 setTitle:@"Clear cache" forState:UIControlStateNormal];
    [self.button2 addTarget:self action:@selector(clearCacheAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button2];
    
    self.button3 = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.button3 setTitle:@"Request Text" forState:UIControlStateNormal];
    [self.button3 addTarget:self action:@selector(downloadTextAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button3];
    
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.button1.frame = CGRectMake(10, 20, kButtonSize.width, kButtonSize.height);
    self.button2.frame = CGRectMake(CGRectGetMaxX(self.button1.frame) + 5, 20, kButtonSize.width, kButtonSize.height);
    self.button3.frame = CGRectMake(CGRectGetMaxX(self.button2.frame) + 5, 20, kButtonSize.width, kButtonSize.height);
    
    self.imageView.frame = CGRectMake(0, CGRectGetMaxY(self.button3.frame) + 5, self.view.bounds.size.width, 300.0);
    
    CGFloat textViewTop = CGRectGetMaxY(self.imageView.frame) + 5;
    self.webiew.frame = CGRectMake(0, textViewTop, self.view.bounds.size.width, self.view.bounds.size.height - textViewTop);
}

#pragma mark - Actions

- (void)downloadImageAction:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://lorempixel.com/700/300/"];
    [[TWNetworkManager defaultManager]
     imageAtURL:url
     completion:^(UIImage *image, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         self.imageView.image = image;
     }];
}

- (void)clearCacheAction:(id)sender
{
    [[TWNetworkManager defaultManager] reset];
}

- (void)downloadTextAction:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://whatthecommit.com"];
    [[TWNetworkManager defaultManager]
     requestURL:url
     type:TWNetworkHTTPMethodGET
     completion:^(NSData *data, NSString *localFilepath, BOOL isFromCache, NSError *error) {
         
         NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
         [self.webiew loadHTMLString:string baseURL:url];
     }];
}

@end
