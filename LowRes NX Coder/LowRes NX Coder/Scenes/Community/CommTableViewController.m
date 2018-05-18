//
//  CommTableViewController.m
//  LowRes NX Coder
//
//  Created by Timo Kloss on 16/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

#import "CommTableViewController.h"
#import "CommunityModel.h"
#import "CommLogInViewController.h"
#import "CommDetailViewController.h"
#import "CommUsersViewController.h"
#import "UIViewController+LowResCoder.h"

@interface CommTableViewController ()
@property UIBarButtonItem *loginItem;
@property BOOL isVisible;
@end

@implementation CommTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppActivate:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isVisible = YES;
    [self updateUser];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isVisible = NO;
    self.shouldReload = NO;
}

- (void)updateUser {
    if (self.navigationController.viewControllers.firstObject == self) {
        LCCUser *user = [CommunityModel sharedInstance].currentUser;
        if (user) {
            UIImage *userImage = [[UIImage imageNamed:@"profile"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.loginItem = [[UIBarButtonItem alloc] initWithImage:userImage style:UIBarButtonItemStylePlain target:self action:@selector(onUserTapped:)];
        } else {
            self.loginItem = [[UIBarButtonItem alloc] initWithTitle:@"Log In" style:UIBarButtonItemStylePlain target:self action:@selector(onLoginItemTapped:)];
        }
        self.navigationItem.leftBarButtonItem = self.loginItem;
    }
}

- (void)onUserChanged:(NSNotification *)notification {
    [self updateUser];
}

- (void)onAppActivate:(NSNotification *)notification {
    if (self.isVisible) {
        [self reloadContent];
        self.shouldReload = NO;
    } else {
        self.shouldReload = YES;
    }
}

- (void)reloadContent {
    // Override
}

- (void)onLoginItemTapped:(id)sender {
    CommLogInViewController *vc = [CommLogInViewController create];
    [self presentInNavigationViewController:vc];
}

- (void)onUserTapped:(id)sender {
    LCCUser *user = [CommunityModel sharedInstance].currentUser;
    if (!user) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:user.username message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Profile" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
        [vc setUser:user mode:CommListModeProfile];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Following" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CommUsersViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommUsersView"];
        [vc setUser:user mode:CommUsersModeFollowing];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Log Out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self onLogOutTapped];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    alert.popoverPresentationController.barButtonItem = sender;
}

- (void)onLogOutTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do you really want to log out?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Log Out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[CommunityModel sharedInstance] logOut];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
