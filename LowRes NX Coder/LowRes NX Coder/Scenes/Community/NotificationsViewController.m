//
//  NotificationsViewController.m
//  Pixels
//
//  Created by Timo Kloss on 25/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "NotificationsViewController.h"
#import "CommunityModel.h"
#import "UIViewController+LowResCoder.h"
#import "LowRes_NX_Coder-Swift.h"
#import "CommPostViewController.h"
#import "CommDetailViewController.h"
#import "AppStyle.h"
#import "UITableView+Parse.h"

@interface NotificationsViewController ()

@property UIActivityIndicatorView *activityIndicator;
@property NSArray <LCCNotification *> *notifications;
@property NSDate *unreadDate;

@end

@implementation NotificationsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicator.hidesWhenStopped = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 63;
    
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    self.navigationItem.rightBarButtonItem = activityItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotificationsChanged:) name:NotificationsUpdateNotification object:nil];
    
    self.notifications = [CommunityModel sharedInstance].notifications.copy;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.unreadDate = [CommunityModel sharedInstance].currentUser.notificationsOpenedDate;
    [[CommunityModel sharedInstance] onOpenNotifications];
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationsUpdateNotification object:nil];
}

- (void)onNotificationsChanged:(NSNotification *)notification
{
    if ([CommunityModel sharedInstance].isUpdatingNotifications)
    {
        [self.activityIndicator startAnimating];
    }
    else
    {
        [self.activityIndicator stopAnimating];
        NSArray *oldNotifications = self.notifications;
        self.notifications = [CommunityModel sharedInstance].notifications.copy;
        [self.tableView reloadDataAnimatedWithOldArray:oldNotifications newArray:self.notifications inSection:0 offset:0];
        [self.refreshControl endRefreshing];
        
//        self.unreadDate = [CommunityModel sharedInstance].currentUser.notificationsOpenedDate;
//        [[CommunityModel sharedInstance] onOpenNotifications];
    }
}

- (IBAction)onRefreshPulled:(id)sender
{
    [[CommunityModel sharedInstance] loadNotifications];
    if (![CommunityModel sharedInstance].currentUser)
    {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
    
    LCCNotification *notification = self.notifications[indexPath.row];
    cell.notification = notification;
    cell.isUnread = (notification.createdAt.timeIntervalSinceReferenceDate > self.unreadDate.timeIntervalSinceReferenceDate);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LCCNotification *notification = self.notifications[indexPath.row];
    
    switch (notification.type)
    {
        case LCCNotificationTypeComment:
        case LCCNotificationTypeReportComment: {
            CommPostViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommPostView"];
            [vc setPost:notification.postObject mode:CommPostModePost commentId:notification.comment];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
            
        case LCCNotificationTypeLike:
        case LCCNotificationTypeShare:
        case LCCNotificationTypeFollow: {
            CommDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CommDetailView"];
            [vc setUser:notification.senderObject mode:CommListModeProfile];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        
        default:
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
    }
}

@end


@interface NotificationCell()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@end

@implementation NotificationCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
}

- (void)setNotification:(LCCNotification *)notification
{
    _notification = notification;
    
    NSString *text;
    NSString *name = (notification.senderObject != nil) ? notification.senderObject.username : @"A guest";
    switch (notification.type)
    {
        case LCCNotificationTypeComment:
            text = [NSString stringWithFormat:@"%@ commented on '%@'", name, notification.postObject.title];
            break;
            
        case LCCNotificationTypeLike:
            text = [NSString stringWithFormat:@"%@ likes '%@'", name, notification.postObject.title];
            break;
            
        case LCCNotificationTypeShare:
            text = [NSString stringWithFormat:@"%@ featured '%@'", name, notification.postObject.title];
            break;
            
        case LCCNotificationTypeFollow:
            text = [NSString stringWithFormat:@"%@ follows you", name];
            break;
            
        case LCCNotificationTypeReportComment:
            text = [NSString stringWithFormat:@"%@ reported an inappropriate comment on '%@'", name, notification.postObject.title];
            break;
            
        default:
            text = @"Unknown notification";
            break;
    }
    
    self.textView.text = text;
    self.dateLabel.text = [NSDateFormatter localizedStringFromDate:notification.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
}

- (void)setIsUnread:(BOOL)isUnread
{
    _isUnread = isUnread;
    if (isUnread)
    {
        self.textView.font = [UIFont boldSystemFontOfSize:16];
    }
    else
    {
        self.textView.font = [UIFont systemFontOfSize:16];
    }
}

@end
