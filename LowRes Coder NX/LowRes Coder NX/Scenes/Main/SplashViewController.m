//
//  SplashViewController.m
//  Pixels
//
//  Created by Timo Kloss on 16/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "SplashViewController.h"
#import "AppStyle.h"

@interface SplashViewController ()

@property BOOL animationDone;
@property BOOL timerDone;

@end

@implementation SplashViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimerComplete:) userInfo:nil repeats:NO];
    
    [UIView animateWithDuration:1 delay:0.3 options:UIViewAnimationOptionCurveLinear animations:^{
        
    } completion:^(BOOL finished) {
        
 /*
            [[ModelManager sharedManager] createDefaultProjects];
            
            // prepare root folder (maybe it needs to be created)
            [[ModelManager sharedManager] rootFolder];
*/
        self.animationDone = YES;
        [self checkComplete];
        
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)onTimerComplete:(id)sender
{
    self.timerDone = YES;
    [self checkComplete];
}

- (void)checkComplete
{
    if (self.animationDone && self.timerDone)
    {
        [self showApp];
    }
}

- (void)showApp
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AppStart"];
    id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = vc;
    
    [UIView transitionWithView:appDelegate.window duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        appDelegate.window.rootViewController = vc;
    } completion:nil];
}

@end
