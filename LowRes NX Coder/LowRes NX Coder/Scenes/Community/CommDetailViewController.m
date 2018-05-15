//
//  CommunityListViewController.m
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommDetailViewController.h"
#import "CommunityModel.h"
#import "CommPostViewController.h"
#import "UIImageView+WebCache.h"
#import "CommUsersViewController.h"
#import "CommEditUserViewController.h"
#import "CommLogInViewController.h"
#import "UIViewController+LowResCoder.h"
#import "LowRes_NX_Coder-Swift.h"
#import "AppController.h"
#import "GORCycleManager.h"
#import "UITableView+Parse.h"
#import "CommStatusUpdateViewController.h"
#import "ActivityView.h"
#import "BlockerView.h"
#import "LimitedTextView.h"
#import "AppStyle.h"

typedef NS_ENUM(NSInteger, CellTag) {
    CellTagNoAction,
    CellTagPost,
    CellTagFollowers,
    CellTagFollowing,
    CellTagWriteStatus,
    CellTagAdminResetPassword,
    CellTagForum,
    CellTagEssentials,
    CellTagDiscover
};

typedef NS_ENUM(NSInteger, Section) {
    SectionInfo,
    SectionPosts,
    Section_count
};

static const NSInteger LIMIT = 25;

@interface CommDetailViewController ()

@property LCCUser *user;
@property CommListMode mode;

@property NSMutableArray *posts;
@property NSMutableDictionary *usersById;
@property NSMutableDictionary *statsById;

@property CommProfileCell *profileCell;
@property ActivityView *activityView;
@property BOOL userNeedsUpdate;
@property (nonatomic) LCCPostCategory filterCategory;
@property int currentOffset;
@property NSString *currentRoute;
@property BOOL hasMorePosts;

@end

@implementation CommDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [AppStyle tableBackgroundColor];
    
    self.activityView = [ActivityView view];
    
    if ([self isModal])
    {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneTapped:)];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.profileCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommProfileCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFollowsChanged:) name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserChanged:) name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPostDeleted:) name:PostDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatsChanged:) name:PostStatsChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FollowsChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PostStatsChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.mode == CommListModeUndefined)
    {
        LCCUser *user = [CommunityModel sharedInstance].currentUser;
        [self setUser:user mode:CommListModeNews];
    }
    if (self.activityView.state == ActivityStateUnknown)
    {
        [self updateDataForceReload:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)setFilterCategory:(LCCPostCategory)filterCategory
{
    _filterCategory = filterCategory;
    [self.posts removeAllObjects];
    [self updateDataForceReload:NO];
    [self.tableView reloadData];
}

- (void)setUser:(LCCUser *)user mode:(CommListMode)mode
{
    if ([user isMe])
    {
        // use global instance of user
        self.user = [CommunityModel sharedInstance].currentUser;
    }
    else
    {
        self.user = user;
    }
    self.mode = mode;
}

- (IBAction)onRefreshPulled:(id)sender
{
    if (self.activityView.state != ActivityStateBusy)
    {
        [self updateDataForceReload:YES];
    }
    else
    {
        [self.refreshControl endRefreshing];
    }
}

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onFollowsChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeNews || self.mode == CommListModeDiscover)
    {
        [self updateDataForceReload:NO];
    }
    else if (self.mode == CommListModeProfile)
    {
        self.userNeedsUpdate = YES;
        [self.tableView reloadData];
    }
}

- (void)onUserChanged:(NSNotification *)notification
{
    if (self.mode == CommListModeNews || self.mode == CommListModeDiscover)
    {
        self.user = [CommunityModel sharedInstance].currentUser;
        [self updateDataForceReload:NO];
    }
    else if (self.mode == CommListModeProfile)
    {
        if ([self.user isMe])
        {
            self.userNeedsUpdate = YES;
            [self.tableView reloadData];
        }
    }
}

- (void)onPostDeleted:(NSNotification *)notification
{
    NSString *deletedPostId = notification.userInfo[@"postId"];
    BOOL changed = NO;
    for (int i = (int)self.posts.count - 1; i >= 0; i--)
    {
        LCCPost *post = self.posts[i];
        if (   [post.objectId isEqualToString:deletedPostId]
            || [post.sharedPost isEqualToString:deletedPostId])
        {
            [self.posts removeObjectAtIndex:i];
            changed = YES;
            break;
        }
    }
    if (changed)
    {
        [self.tableView reloadData];
    }
}

- (void)onStatsChanged:(NSNotification *)notification
{
    LCCPostStats *stats = notification.userInfo[@"stats"];
    self.statsById[stats.objectId] = stats;
    [self updateVisiblePosts];
}

- (void)updateDataForceReload:(BOOL)forceReload
{
    switch (self.mode)
    {
        case CommListModeNews: {
            self.title = @"Community";
            self.currentOffset = 0;
            self.currentRoute = [NSString stringWithFormat:@"users/%@/news", (self.user ? self.user.objectId : @"guest")];
            [self loadCurrentQueryForceReload:forceReload];
            break;
        }
        case CommListModeForum: {
            self.title = @"Forum";
            self.currentOffset = 0;
            self.currentRoute = @"forum";
            [self loadCurrentQueryForceReload:forceReload];
            break;
        }
        case CommListModeDiscover: {
            self.title = @"Discover";
            self.currentOffset = 0;
            self.currentRoute = [NSString stringWithFormat:@"users/%@/discover", self.user.objectId];
            [self loadCurrentQueryForceReload:forceReload];
            break;
        }
        case CommListModeEssentials: {
            self.title = @"Essentials";
            self.currentOffset = 0;
            self.currentRoute = [NSString stringWithFormat:@"essentials"];
            [self loadCurrentQueryForceReload:forceReload];
            break;
        }
        case CommListModeProfile: {
            self.title = self.user.username;
            self.currentOffset = 0;
            self.currentRoute = [NSString stringWithFormat:@"users/%@", self.user.objectId];
            [self loadCurrentQueryForceReload:forceReload];
            break;
        }
        case CommListModeUndefined:
            break;
    }
}

- (void)loadCurrentQueryForceReload:(BOOL)forceReload
{
    BOOL add = (self.currentOffset > 0);
    NSArray *oldPosts = self.posts.copy;
    
    CGRect frame = self.activityView.frame;
    if (add)
    {
        frame.size.height = 60;
    }
    else
    {
        frame.size.height = self.tableView.bounds.size.height;
    }
    self.activityView.frame = frame;
    self.tableView.tableFooterView = self.activityView;
    self.activityView.state = ActivityStateBusy;
    
    if (forceReload)
    {
        [[CommunityModel sharedInstance] clearCache];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"offset"] = @(self.currentOffset);
    params[@"limit"] = @(LIMIT);
    if (self.filterCategory != LCCPostCategoryUndefined)
    {
        params[@"category"] = @(self.filterCategory);
    }
    
    [[CommunityModel sharedInstance].sessionManager GET:self.currentRoute parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        id userDict = responseObject[@"user"];
        if (self.mode == CommListModeProfile && userDict)
        {
            [self.user updateWithDictionary:userDict];
            self.userNeedsUpdate = YES;
        }
        
        NSArray *posts = [LCCPost objectsFromArray:responseObject[@"posts"]];
        NSDictionary *usersById = [LCCUser objectsByIdFromArray:responseObject[@"users"]];
        NSDictionary *statsById = [LCCPostStats objectsByIdFromArray:responseObject[@"postStats"]];
        if (add)
        {
            [self.posts addObjectsFromArray:posts];
            [self.usersById addEntriesFromDictionary:usersById];
            [self.statsById addEntriesFromDictionary:statsById];
        }
        else
        {
            self.posts = posts.mutableCopy;
            self.usersById = usersById.mutableCopy;
            self.statsById = statsById.mutableCopy;
            
            if (self.user)
            {
                self.usersById[self.user.objectId] = self.user;
            }
        }
        
        self.hasMorePosts = (posts.count == LIMIT);
        self.currentOffset += LIMIT; // for next load
        if (self.mode == CommListModeProfile)
        {
            // don't fetch complete user again for following pages
            self.currentRoute = [NSString stringWithFormat:@"users/%@/posts", self.user.objectId];
        }
        if (forceReload && !add)
        {
            [self updateVisiblePosts];
            [self.tableView reloadDataAnimatedWithOldArray:oldPosts newArray:self.posts inSection:SectionPosts offset:1];
        }
        else
        {
            [self.tableView reloadData];
        }
        
        self.activityView.state = ActivityStateReady;
        self.tableView.tableFooterView = nil;
        [self.refreshControl endRefreshing];

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        [self.activityView failWithMessage:error.presentableError.localizedDescription];
        [self.refreshControl endRefreshing];

    }];
}

- (void)updateVisiblePosts
{
    NSArray *cells = self.tableView.visibleCells;
    for (CommPostCell *cell in cells)
    {
        if ([cell isKindOfClass:[CommPostCell class]])
        {
            for (LCCPost *post in self.posts)
            {
                if ([post.objectId isEqualToString:cell.post.objectId])
                {
                    LCCPostStats *stats = self.statsById[post.stats];
                    [cell setStats:stats];
                    break;
                }
            }
        }
    }
}

- (IBAction)onActionTapped:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if ([self.user isMe])
    {
        // Edit
        UIViewController *vc = [CommEditUserViewController create];
        [self presentInNavigationViewController:vc];
    }
    else if (![CommunityModel sharedInstance].currentUser)
    {
        UIViewController *vc = [CommLogInViewController create];
        [self presentInNavigationViewController:vc];
    }
    else if ([[CommunityModel sharedInstance] userInFollowing:self.user])
    {
        button.enabled = NO;
        [[CommunityModel sharedInstance] unfollowUser:self.user];
    }
    else
    {
        button.enabled = NO;
        [[CommunityModel sharedInstance] followUser:self.user];
    }
}

- (IBAction)onMoreTapped:(id)sender
{
    [self.profileCell toggleDetailSize];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (IBAction)onFilterChanged:(UISegmentedControl *)sender
{
    if (self.mode == CommListModeForum)
    {
        switch (sender.selectedSegmentIndex)
        {
            case 0: self.filterCategory = LCCPostCategoryUndefined; break;
            case 1: self.filterCategory = LCCPostCategoryForumHowTo; break;
            case 2: self.filterCategory = LCCPostCategoryForumCollaboration; break;
            case 3: self.filterCategory = LCCPostCategoryForumDiscussion; break;
        }
    }
    else
    {
        switch (sender.selectedSegmentIndex)
        {
            case 0: self.filterCategory = LCCPostCategoryUndefined; break;
            case 1: self.filterCategory = LCCPostCategoryGame; break;
            case 2: self.filterCategory = LCCPostCategoryTool; break;
            case 3: self.filterCategory = LCCPostCategoryDemo; break;
            case 4: self.filterCategory = LCCPostCategoryStatus; break;
        }
    }
}

- (void)deletePost:(LCCPost *)post indexPath:(NSIndexPath *)indexPath
{
    [BlockerView show];
    
    NSString *route = [NSString stringWithFormat:@"/posts/%@", post.objectId];
    [[CommunityModel sharedInstance].sessionManager DELETE:route parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [BlockerView dismiss];
        [self.posts removeObject:post];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [[CommunityModel sharedInstance] clearCache];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        [BlockerView dismiss];
        [[CommunityModel sharedInstance] handleAPIError:error title:@"Could not delete post" viewController:self];
        
    }];
}

- (void)resetPassword
{
    [self showConfirmAlertWithTitle:@"Do you really want to reset this user's password?" message:nil block: ^{
        NSDictionary *params = @{@"userId": self.user.objectId};
        [[CommunityModel sharedInstance].sessionManager POST:@"/resetPassword" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            
            [BlockerView dismiss];
            NSString *password = responseObject[@"password"];
            
            // copy password to clipboard
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = password;
            
            // show message
            NSString *message = [NSString stringWithFormat:@"New password '%@' copied to clipboard.", password];
            [self showAlertWithTitle:@"Password successfully reset" message:message block:nil];
            
        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
            
            [BlockerView dismiss];
            [[CommunityModel sharedInstance] handleAPIError:error title:@"Could not reset password" viewController:self];
            
        }];
    }];
}

#pragma mark - Table view

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionInfo && indexPath.row == 0)
    {
        return (self.mode == CommListModeProfile) ? 122 : 60;
    }
    else if (indexPath.section == SectionPosts)
    {
        return 84;
    }
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (self.posts != nil ? Section_count : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SectionInfo)
    {
        if (self.mode == CommListModeProfile)
        {
            if ([self.user isMe] || [[CommunityModel sharedInstance].currentUser canResetAnyPassword])
            {
                // status update / admin reset password
                return 4;
            }
            return 3;
        }
        else if (self.mode == CommListModeForum)
        {
            return 2;
        }
        else if (self.mode == CommListModeNews)
        {
            BOOL isLoggedIn = [CommunityModel sharedInstance].currentUser != nil;
            return isLoggedIn ? 3 : 2;
        }
        else
        {
            return 1;
        }
    }
    else if (section == SectionPosts)
    {
        return self.posts.count + 1; // posts + filter
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SectionPosts)
    {
        return self.mode == CommListModeNews ? @"News" : @"Posts";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionInfo)
    {
        if (self.mode == CommListModeProfile)
        {
            if (indexPath.row == 0)
            {
                if (self.profileCell.user != self.user || self.userNeedsUpdate)
                {
                    self.profileCell.user = self.user;
                    self.userNeedsUpdate = NO;
                }
                return self.profileCell;
            }
            else if (indexPath.row == 1)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailMenuCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Followers";
                cell.tag = CellTagFollowers;
                return cell;
            }
            else if (indexPath.row == 2)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailMenuCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Following";
                cell.tag = CellTagFollowing;
                return cell;
            }
            else if (indexPath.row == 3)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
                if ([self.user isMe])
                {
                    cell.textLabel.text = @"Write Status Update";
                    cell.tag = CellTagWriteStatus;
                }
                else
                {
                    cell.textLabel.text = @"Reset Password";
                    cell.tag = CellTagAdminResetPassword;
                }
                return cell;
            }
        }
        else if (self.mode == CommListModeNews)
        {
            if (indexPath.row == 0)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailMenuCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Forum";
                cell.tag = CellTagForum;
                return cell;
            }
            else if (indexPath.row == 1)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailMenuCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Essentials";
                cell.tag = CellTagEssentials;
                return cell;
            }
            else if (indexPath.row == 2)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailMenuCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Discover";
                cell.tag = CellTagDiscover;
                return cell;
            }
        }
        else if (self.mode == CommListModeDiscover)
        {
            CommInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommInfoCell" forIndexPath:indexPath];
            cell.infoTextLabel.text = @"Discover new programmers! Here you see posts of users you don't follow yet.";
            return cell;
        }
        else if (self.mode == CommListModeForum)
        {
            if (indexPath.row == 0)
            {
                CommInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommInfoCell" forIndexPath:indexPath];
                cell.infoTextLabel.text = @"Do you need help or have an idea? Post it here in the Forum, where anyone can see it.";
                return cell;
            }
            else if (indexPath.row == 1)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
                cell.textLabel.text = @"Start New Topic";
                cell.tag = CellTagWriteStatus;
                return cell;
            }

        }
        else if (self.mode == CommListModeEssentials)
        {
            CommInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommInfoCell" forIndexPath:indexPath];
            cell.infoTextLabel.text = @"A selection of the best LowRes NX programs.";
            return cell;
        }
    }
    else if (indexPath.section == SectionPosts)
    {
        if (indexPath.row == 0)
        {
            CommFilterCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommFilterCell" forIndexPath:indexPath];
            cell.mode = self.mode;
            cell.postCategory = self.filterCategory;
            return cell;
        }
        else
        {
            LCCPost *post = self.posts[indexPath.row - 1];
            LCCUser *user = self.usersById[post.user];
            LCCPostStats *stats = self.statsById[post.stats];
            NSString *cellType = (post.type == LCCPostTypeStatus || post.image == nil) ? @"StatusCell" : @"ProgramCell"; //TODO should check type only
            CommPostCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType forIndexPath:indexPath];
            [cell setPost:post
                    stats:stats
                     user:user
                 showName:(self.mode == CommListModeNews || self.mode == CommListModeDiscover || self.mode == CommListModeEssentials || self.mode == CommListModeForum)];
            cell.tag = CellTagPost;
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (cell.tag)
    {
        case CellTagFollowers: {
            CommUsersViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommUsersView"];
            [vc setUser:self.user mode:CommUsersModeFollowers];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case CellTagFollowing: {
            CommUsersViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommUsersView"];
            [vc setUser:self.user mode:CommUsersModeFollowing];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case CellTagPost: {
            CommPostViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommPostView"];
            LCCPost *post = self.posts[indexPath.row - 1];
            if (post.isShared)
            {
                LCCPost *sharedPost = [[LCCPost alloc] initWithObjectId:post.sharedPost];
                [vc setPost:sharedPost mode:CommPostModePost];
            }
            else
            {
                [vc setPost:post mode:CommPostModePost];
            }
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case CellTagWriteStatus: {
            if (![CommunityModel sharedInstance].currentUser)
            {
                CommLogInViewController *vc = [CommLogInViewController create];
                [self presentInNavigationViewController:vc];
            }
            else
            {
                LCCPostType postType = (self.mode == CommListModeForum) ? LCCPostTypeForum : LCCPostTypeStatus;
                UIViewController *vc = [CommStatusUpdateViewController createWithStoryboard:self.storyboard postType:postType completion:^(LCCPost *post, LCCPostStats *stats) {
                    self.statsById[stats.objectId] = stats;
                    LCCUser *currentUser = [CommunityModel sharedInstance].currentUser;
                    self.usersById[currentUser.objectId] = currentUser;
                    if (self.filterCategory == LCCPostCategoryUndefined || post.category == self.filterCategory)
                    {
                        [self.posts insertObject:post atIndex:0];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:SectionPosts];
                        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    else
                    {
                        self.filterCategory = LCCPostCategoryUndefined;
                    }
                }];
                
                [self presentViewController:vc animated:YES completion:nil];
            }
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case CellTagAdminResetPassword: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self resetPassword];
            break;
        }
        case CellTagForum: {
            CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
            [vc setUser:self.user mode:CommListModeForum];
            [self.navigationController showViewController:vc sender:self];
            break;
        }
        case CellTagDiscover: {
            CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
            [vc setUser:self.user mode:CommListModeDiscover];
            [self.navigationController showViewController:vc sender:self];
            break;
        }
        case CellTagEssentials: {
            CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
            [vc setUser:self.user mode:CommListModeEssentials];
            [self.navigationController showViewController:vc sender:self];
            break;
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionPosts && indexPath.row > 0)
    {
        LCCUser *user = [CommunityModel sharedInstance].currentUser;
        LCCPost *post = self.posts[indexPath.row - 1];
        
        if ([user isNewsUser] && post.isShared && [post.user isEqualToString:user.objectId])
        {
            return UITableViewCellEditingStyleDelete;
        }
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionPosts && indexPath.row > 0)
    {
        LCCPost *post = self.posts[indexPath.row - 1];
        [self deletePost:post indexPath:indexPath];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (   self.hasMorePosts && self.activityView.state == ActivityStateReady
        && scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.bounds.size.height - 80.0)
    {
        [self loadCurrentQueryForceReload:NO];
    }
}

@end


@interface CommProfileCell() <LimitedTextViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet LimitedTextView *detailTextView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@end

@implementation CommProfileCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.detailTextView.textContainer.lineFragmentPadding = 0;
    self.detailTextView.textContainerInset = UIEdgeInsetsZero;
    self.detailTextView.heightLimit = 154;
    self.detailTextView.limitEnabled = YES;
    self.detailTextView.limitDelegate = self;
}

- (void)setUser:(LCCUser *)user
{
    _user = user;
    self.titleLabel.text = user.username;
    if (user.about.length > 0)
    {
        self.detailTextView.text = [user.about stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.detailTextView.alpha = 1.0;
    }
    else
    {
        self.detailTextView.text = @"No about text written yet";
        self.detailTextView.alpha = 0.5;
    }
    
    if ([self.user isMe])
    {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
        [self.actionButton setTitle:@"Edit" forState:UIControlStateNormal];
    }
    else if ([self.user isNewsUser])
    {
        self.actionButton.hidden = YES;
    }
    else
    {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
        if ([CommunityModel sharedInstance].currentUser && [[CommunityModel sharedInstance] userInFollowing:user])
        {
            [self.actionButton setTitle:@"Following ✓" forState:UIControlStateNormal];
        }
        else
        {
            [self.actionButton setTitle:@"Follow" forState:UIControlStateNormal];
        }
    }
}

- (void)textView:(LimitedTextView *)textView didChangeOversize:(BOOL)oversize
{
    if (oversize)
    {
        [self updateMoreButton];
        self.moreButton.hidden = NO;
    }
    else
    {
        self.moreButton.hidden = YES;
    }
}

- (void)toggleDetailSize
{
    self.detailTextView.limitEnabled = !self.detailTextView.limitEnabled;
    [self updateMoreButton];
}

- (void)updateMoreButton
{
    if (self.detailTextView.limitEnabled)
    {
        [self.moreButton setTitle:@"More..." forState:UIControlStateNormal];
    }
    else
    {
        [self.moreButton setTitle:@"Less" forState:UIControlStateNormal];
    }
}

@end


@implementation CommInfoCell
@end


@implementation CommFilterCell

- (void)setMode:(CommListMode)mode
{
    [self.segmentedControl removeAllSegments];
    [self.segmentedControl insertSegmentWithTitle:@"All" atIndex:0 animated:NO];
    switch (mode)
    {
        case CommListModeForum:
            [self.segmentedControl insertSegmentWithTitle:@"How To" atIndex:1 animated:NO];
            [self.segmentedControl insertSegmentWithTitle:@"Collaboration" atIndex:2 animated:NO];
            [self.segmentedControl insertSegmentWithTitle:@"Discussion" atIndex:3 animated:NO];
            break;
            
        default:
            [self.segmentedControl insertSegmentWithTitle:@"Games" atIndex:1 animated:NO];
            [self.segmentedControl insertSegmentWithTitle:@"Tools" atIndex:2 animated:NO];
            [self.segmentedControl insertSegmentWithTitle:@"Demos" atIndex:3 animated:NO];
            if (mode != CommListModeEssentials)
            {
                [self.segmentedControl insertSegmentWithTitle:@"Status" atIndex:4 animated:NO];
            }
            break;
    }
}

- (void)setPostCategory:(LCCPostCategory)postCategory
{
    switch (postCategory)
    {
        case LCCPostCategoryUndefined:
            self.segmentedControl.selectedSegmentIndex = 0;
            break;
        case LCCPostCategoryGame:
        case LCCPostCategoryForumHowTo:
            self.segmentedControl.selectedSegmentIndex = 1;
            break;
        case LCCPostCategoryTool:
        case LCCPostCategoryForumCollaboration:
            self.segmentedControl.selectedSegmentIndex = 2;
            break;
        case LCCPostCategoryDemo:
        case LCCPostCategoryForumDiscussion:
            self.segmentedControl.selectedSegmentIndex = 3;
            break;
        case LCCPostCategoryStatus:
            self.segmentedControl.selectedSegmentIndex = 4;
            break;
    }
}

@end

@interface CommPostCell()
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;

@property (nonatomic) LCCPost *post;
@property (nonatomic) LCCUser *user;
@end

@implementation CommPostCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    CALayer *layer = self.iconImageView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 4;
    layer.borderWidth = 0.5;
    layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
}

- (void)setPost:(LCCPost *)post stats:(LCCPostStats *)stats user:(LCCUser *)user showName:(BOOL)showName
{
    _post = post;
    _user = user;
    
    self.starImageView.hidden = !([user isNewsUser] || stats.featured);
    
    self.titleLabel.text = post.title;

    NSMutableArray *infos = [NSMutableArray arrayWithCapacity:4];
    if (post.category != LCCPostCategoryStatus)
    {
        [infos addObject:[post categoryString]];
    }
    if (showName)
    {
        NSString *name = (post.isShared) ? [NSString stringWithFormat:@"Shared by %@", user.username] : user.username;
        [infos addObject:name];
    }
    NSString *date = [NSDateFormatter localizedStringFromDate:post.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    [infos addObject:date];
    self.dateLabel.text = [infos componentsJoinedByString:@" - "];
    
    if (self.iconImageView)
    {
        [self.iconImageView sd_setImageWithURL:post.image];
    }
    
    [self setStats:stats];
}

- (void)setStats:(LCCPostStats *)stats
{
    if (stats)
    {
        NSString *likesWord = stats.numLikes == 1 ? @"Like" : @"Likes";
        NSString *downloadsWord = stats.numDownloads == 1 ? @"Download" : @"Downloads";
        NSString *commentsWord = stats.numComments == 1 ? @"Comment" : @"Comments";
        
        if (   self.post.category == LCCPostCategoryStatus // checks category, because of shared posts. //TODO change to type when isShared works
            || self.post.type == LCCPostTypeForum)
        {
            self.statsLabel.text = [NSString stringWithFormat:@"%d %@, %d %@",
                                    stats.numLikes, likesWord,
                                    stats.numComments, commentsWord];
        }
        else
        {
            self.statsLabel.text = [NSString stringWithFormat:@"%d %@, %d %@, %d %@",
                                    stats.numLikes, likesWord,
                                    stats.numDownloads, downloadsWord,
                                    stats.numComments, commentsWord];
        }
    }
    else
    {
        self.statsLabel.text = @" ";
    }
}

@end
