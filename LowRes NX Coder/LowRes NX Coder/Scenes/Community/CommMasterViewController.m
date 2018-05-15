//
//  CommunityMasterViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommMasterViewController.h"
#import "CommDetailViewController.h"
#import "CommunityModel.h"
#import "CommLogInViewController.h"
#import "UIViewController+LowResCoder.h"
#import "LowRes_NX_Coder-Swift.h"
#import "AppController.h"
#import "ActionTableViewCell.h"
#import "AppStyle.h"

typedef NS_ENUM(NSInteger, Section) {
    SectionMain,
    SectionAccount,
    SectionFollowing,
    Section_count
};

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNews,
    CellTagAccount,
    CellTagLogIn,
    CellTagLogOut,
    CellTagFollowing
};

@interface CommMasterViewController ()

@property NSIndexPath *newsIndexPath;
@property NSIndexPath *currentSelection;

@end

@implementation CommMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [AppStyle tableBackgroundColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsLoadNotification object:nil];
    
    self.newsIndexPath = [NSIndexPath indexPathForRow:0 inSection:SectionMain];
    self.currentSelection = self.newsIndexPath;
    
    [[CommunityModel sharedInstance] updateCurrentUser];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsLoadNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.clearsSelectionOnViewWillAppear = self.splitViewController.collapsed;
    [super viewWillAppear:animated];
}

- (void)showCurrentSelection
{
    if (!self.splitViewController.collapsed)
    {
        [self.tableView selectRowAtIndexPath:self.currentSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
    if (![CommunityModel sharedInstance].currentUser && ![self.currentSelection isEqual:self.newsIndexPath])
    {
        // show news
        self.currentSelection = self.newsIndexPath;
        if (!self.splitViewController.collapsed)
        {
            [self.tableView selectRowAtIndexPath:self.currentSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self performSegueWithIdentifier:@"Detail" sender:self];
        }
    }
    else
    {
        [self showCurrentSelection];
    }
}

- (void)onFollowsChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
    [self showCurrentSelection];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([CommunityModel sharedInstance].follows.count > 0 ? Section_count : Section_count - 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case SectionMain:
            return @"Main";
            
        case SectionAccount:
            return @"Your Account";
            
        case SectionFollowing:
            return @"Following";
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BOOL loggedIn = [CommunityModel sharedInstance].currentUser != nil;
    switch (section)
    {
        case SectionMain:
            return 1;
            
        case SectionAccount:
            return loggedIn ? 2 : 1;
            
        case SectionFollowing:
            return [CommunityModel sharedInstance].follows.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section)
    {
        case SectionMain: {
            if (indexPath.row == 0)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
                cell.textLabel.text = @"News";
                cell.tag = CellTagNews;
            }
            break;
        }
        case SectionAccount: {
            if (indexPath.row == 0)
            {
                LCCUser *user = [CommunityModel sharedInstance].currentUser;
                if (user)
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
                    cell.textLabel.text = user.username;
                    cell.tag = CellTagAccount;
                }
                else
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
                    cell.textLabel.text = @"Log In / Register";
                    cell.tag = CellTagLogIn;
                    [((ActionTableViewCell *)cell) setDisabled:NO wheel:NO];
                }
            }
            else if (indexPath.row == 1)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Log Out";
                cell.tag = CellTagLogOut;
            }
            break;
        }
        case SectionFollowing: {
            LCCUser *followUser = [CommunityModel sharedInstance].follows[indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
            cell.textLabel.text = followUser.username;
            cell.tag = CellTagFollowing;
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag)
    {
        case CellTagLogIn: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            UIViewController *vc = [CommLogInViewController create];
            [self presentInNavigationViewController:vc];
            break;
        }
        case CellTagLogOut: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [((ActionTableViewCell *)cell) setDisabled:YES wheel:YES];
            [[CommunityModel sharedInstance] logOut];
            break;
        }
        default: {
            self.currentSelection = indexPath;
            break;
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Detail"])
    {
        CommDetailViewController *vc = (CommDetailViewController *)[[segue destinationViewController] topViewController];
        
        switch (cell.tag)
        {
            case CellTagNews: {
                LCCUser *user = [CommunityModel sharedInstance].currentUser;
                [vc setUser:user mode:CommListModeNews];
                break;
            }
            case CellTagAccount: {
                LCCUser *user = [CommunityModel sharedInstance].currentUser;
                [vc setUser:user mode:CommListModeProfile];
                break;
            }
            case CellTagFollowing: {
                LCCUser *followUser = [CommunityModel sharedInstance].follows[indexPath.row];
                [vc setUser:followUser mode:CommListModeProfile];
                break;
            }
        }
    }
}

@end
