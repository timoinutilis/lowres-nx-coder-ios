//
//  TabBarController.m
//  Pixels
//
//  Created by Timo Kloss on 1/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "TabBarController.h"
#import "HelpSplitViewController.h"
#import "LowRes_NX_Coder-Swift.h"

@interface TabBarController ()

@end

@implementation TabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppController.shared.tabBarController = self;
    
    UIViewController *explorerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ExplorerNav"];

    UIStoryboard *helpStoryboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UIViewController *helpVC = (UIViewController *)[helpStoryboard instantiateInitialViewController];
    
    UIViewController *aboutVC = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutNav"];
    
    explorerVC.tabBarItem = [self itemWithTitle:@"My Programs" imageName:@"programs"];
    helpVC.tabBarItem = [self itemWithTitle:@"Help" imageName:@"help"];
    aboutVC.tabBarItem = [self itemWithTitle:@"About" imageName:@"about"];
    
    self.viewControllers = @[explorerVC, helpVC, aboutVC];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didAddProgram) name:@"ProjectManagerDidAddProgram" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [AppController.shared checkShowProgram];
}

- (UITabBarItem *)itemWithTitle:(NSString *)title imageName:(NSString *)imageName
{
    return [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:imageName] selectedImage:nil];
}

- (void)dismissPresentedViewController:(void (^)(void))completion
{
    UIViewController *topVC = self.selectedViewController;
    if ([topVC isKindOfClass:[UINavigationController class]])
    {
        topVC = ((UINavigationController *)topVC).topViewController;
    }
    if (topVC.presentedViewController)
    {
        [topVC dismissViewControllerAnimated:YES completion:completion];
    }
    else
    {
        completion();
    }
}

- (void)showExplorerAnimated:(BOOL)animated root:(BOOL)root
{
    self.selectedIndex = TabIndexExplorer;
    UINavigationController *nav = (UINavigationController *)self.selectedViewController;
    if (root)
    {
        [nav popToRootViewControllerAnimated:animated];
    }
    else
    {/*
        if (![nav.topViewController isKindOfClass:[ExplorerViewController class]])
        {
            [nav popViewControllerAnimated:animated];
        }*/
    }
}

- (void)showHelpForChapter:(NSString *)chapter
{
    self.selectedIndex = TabIndexHelp;
    HelpSplitViewController *helpVC = (HelpSplitViewController *)self.selectedViewController;
    [helpVC showChapter:chapter];
}

- (void)didAddProgram
{
    if (self.selectedIndex != 0)
    {
        self.selectedIndex = 0;
    }
}

@end
