//
//  CommGuidelinesViewController.m
//  Pixels
//
//  Created by Timo Kloss on 14/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

#import "CommGuidelinesViewController.h"

@interface CommGuidelinesViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation CommGuidelinesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"guidelines" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

@end
