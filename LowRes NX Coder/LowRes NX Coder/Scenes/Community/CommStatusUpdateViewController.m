//
//  CommStatusUpdateViewController.m
//  Pixels
//
//  Created by Timo Kloss on 26/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "CommStatusUpdateViewController.h"
#import "TextFieldTableViewCell.h"
#import "TextViewTableViewCell.h"
#import "GORCycleManager.h"
#import "CommunityModel.h"
#import "AppController.h"
#import "UIViewController+LowResCoder.h"
#import "AppStyle.h"

@interface CommStatusUpdateViewController ()

@property (nonatomic) IBOutlet UIBarButtonItem *sendItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelItem;

@property UITableViewCell *guidelinesCell;
@property TextFieldTableViewCell *titleCell;
@property UITableViewCell *categoryHowToCell;
@property UITableViewCell *categoryCollabCell;
@property UITableViewCell *categoryDiscussCell;
@property TextViewTableViewCell *descriptionCell;

@property (nonatomic) LCCPostCategory selectedCategory;
@property GORCycleManager *cycleManager;

@property (nonatomic) LCCPostType postType;
@property (nonatomic, copy) CommStatusUpdateBlock block;

@end

@implementation CommStatusUpdateViewController

+ (UIViewController *)createWithStoryboard:(UIStoryboard *)storyboard postType:(LCCPostType)type completion:(CommStatusUpdateBlock)block
{
    CommStatusUpdateViewController *vc = (CommStatusUpdateViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CommStatusUpdateView"];
    vc.block = block;
    vc.postType = type;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = vc.modalPresentationStyle;
    nav.modalTransitionStyle = vc.modalTransitionStyle;
    return nav;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = (self.postType == LCCPostTypeForum) ? @"New Topic" : @"Status Update";
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [AppStyle tableBackgroundColor];
    
    int section = 0;
    
    [self setHeaderTitle:@"Title" section:section];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextFieldCell"];
    self.titleCell.textField.placeholder = @"Title";
    [self addCell:self.titleCell];
    
    if (self.postType == LCCPostTypeForum)
    {
        [self setFooterTitle:@"Please choose a descriptive title better than \"I need help\". Before you ask something, check if there are already answers available." section:section];
        
        section++;
        [self setHeaderTitle:@"Category" section:section];
        
        self.categoryHowToCell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
        self.categoryHowToCell.textLabel.text = @"How To";
        self.categoryHowToCell.detailTextLabel.text = @"Questions, tips and tricks";
        [self addCell:self.categoryHowToCell];
        
        self.categoryCollabCell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
        self.categoryCollabCell.textLabel.text = @"Collaboration";
        self.categoryCollabCell.detailTextLabel.text = @"Find people to work together";
        [self addCell:self.categoryCollabCell];
        
        self.categoryDiscussCell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
        self.categoryDiscussCell.textLabel.text = @"Discussion";
        self.categoryDiscussCell.detailTextLabel.text = @"Ideas and anything else";
        [self addCell:self.categoryDiscussCell];
    }
    
    section++;
    [self setHeaderTitle:@"Write Your Text" section:section];
    
    self.descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextViewCell"];
    [self addCell:self.descriptionCell];
    
    self.guidelinesCell = [self.tableView dequeueReusableCellWithIdentifier:@"GuidelinesCell"];
    [self addCell:self.guidelinesCell];
    
    self.cycleManager = [[GORCycleManager alloc] initWithFields:@[self.titleCell.textField, self.descriptionCell.textView]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)setSelectedCategory:(LCCPostCategory)selectedCategory
{
    _selectedCategory = selectedCategory;
    self.categoryHowToCell.accessoryType = (selectedCategory == LCCPostCategoryForumHowTo) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.categoryCollabCell.accessoryType = (selectedCategory == LCCPostCategoryForumCollaboration) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.categoryDiscussCell.accessoryType = (selectedCategory == LCCPostCategoryForumDiscussion) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.view endEditing:YES];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSendTapped:(id)sender
{
    [self.view endEditing:YES];
    if (self.titleCell.textField.text.length == 0 || self.descriptionCell.textView.text.length == 0)
    {
        [self showAlertWithTitle:@"Please fill out all fields!" message:nil block:nil];
    }
    else if (self.postType == LCCPostTypeForum && self.selectedCategory == LCCPostCategoryUndefined)
    {
        [self showAlertWithTitle:@"Please select a category!" message:nil block:nil];
    }
    else
    {
        [self send];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.categoryHowToCell)
    {
        self.selectedCategory = LCCPostCategoryForumHowTo;
    }
    else if (cell == self.categoryCollabCell)
    {
        self.selectedCategory = LCCPostCategoryForumCollaboration;
    }
    else if (cell == self.categoryDiscussCell)
    {
        self.selectedCategory = LCCPostCategoryForumDiscussion;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)send
{
    [self isBusy:YES];
    
    NSString *title = self.titleCell.textField.text;
    NSString *description = self.descriptionCell.textView.text;
    
    // post
    LCCPost *post = [[LCCPost alloc] init];
    post.type = self.postType;
    post.title = title;
    post.detail = description;
    post.category = (self.postType == LCCPostTypeStatus) ? LCCPostCategoryStatus : self.selectedCategory;
    
    NSString *route = [NSString stringWithFormat:@"/users/%@/posts", [CommunityModel sharedInstance].currentUser.objectId];
    NSDictionary *params = [post dirtyDictionary];
    
    [[CommunityModel sharedInstance].sessionManager POST:route parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [post updateWithDictionary:responseObject[@"post"]];
        [post resetDirty];
        
        LCCPostStats *stats = [[LCCPostStats alloc] initWithDictionary:responseObject[@"postStats"]];
        
        [[CommunityModel sharedInstance] clearCache];
        
        if (self.block)
        {
            self.block(post, stats);
            self.block = nil;
        }
        
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        [self isBusy:NO];
        [[CommunityModel sharedInstance] handleAPIError:error title:@"Could not send text" viewController:self];
        
    }];
}

- (void)isBusy:(BOOL)isBusy
{
    self.cancelItem.enabled = !isBusy;
    self.view.userInteractionEnabled = !isBusy;
    if (isBusy)
    {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.frame = CGRectMake(0, 0, 44, 44);
        [activityView startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = self.sendItem;
    }
}

@end
