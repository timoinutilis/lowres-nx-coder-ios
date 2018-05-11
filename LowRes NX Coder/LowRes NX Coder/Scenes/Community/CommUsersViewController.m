//
//  CommUsersViewController.m
//  Pixels
//
//  Created by Timo Kloss on 25/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommUsersViewController.h"
#import "CommunityModel.h"
#import "CommDetailViewController.h"
#import "UIViewController+LowResCoder.h"
#import "LowRes_NX_Coder-Swift.h"
#import "UITableView+Parse.h"
#import "ActivityView.h"

@interface CommUsersViewController ()

@property LCCUser *user;
@property CommUsersMode mode;
@property NSMutableArray *users;
@property ActivityView *activityView;

@end

@implementation CommUsersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.activityView = [ActivityView view];
    
    if ([self isModal])
    {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneTapped:)];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.activityView.state == ActivityStateUnknown)
    {
        [self updateDataForceReload:NO];
    }
}

- (void)setUser:(LCCUser *)user mode:(CommUsersMode)mode
{
    self.user = user;
    self.mode = mode;
    
    self.title = (self.mode == CommUsersModeFollowers) ? @"Followers" : @"Following";
}

- (IBAction)onRefreshPulled:(id)sender
{
    [self updateDataForceReload:YES];
}

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateDataForceReload:(BOOL)forceReload
{
    if (forceReload)
    {
        [[CommunityModel sharedInstance] clearCache];
    }
    
    NSString *route;
    if (self.mode == CommUsersModeFollowers)
    {
        route = [NSString stringWithFormat:@"/users/%@/followers", self.user.objectId];
    }
    else
    {
        route = [NSString stringWithFormat:@"/users/%@/following", self.user.objectId];
    }
    
    self.activityView.state = ActivityStateBusy;
    self.tableView.tableFooterView = self.activityView;
    
    [[CommunityModel sharedInstance].sessionManager GET:route parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

        self.activityView.state = ActivityStateReady;
        self.tableView.tableFooterView = nil;
        
        NSArray *oldUsers = self.users.copy;
        self.users = [LCCUser objectsFromArray:responseObject[@"users"]].mutableCopy;
        if (forceReload)
        {
            [self.tableView reloadDataAnimatedWithOldArray:oldUsers newArray:self.users inSection:0 offset:0];
        }
        else
        {
            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        [self.activityView failWithMessage:error.presentableError.localizedDescription];
        [self.refreshControl endRefreshing];

    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LCCUser *user = self.users[indexPath.row];
    
    CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
    [vc setUser:user mode:CommListModeProfile];
    [self.navigationController pushViewController:vc animated:YES];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    LCCUser *user = self.users[indexPath.row];
    cell.textLabel.text = user.username;
    
    return cell;
}

@end
