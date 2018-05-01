//
//  ShareViewController.m
//  Pixels
//
//  Created by Timo Kloss on 5/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "ShareViewController.h"
#import "CommunityModel.h"
#import "CommLogInViewController.h"
#import "UIViewController+LowResCoder.h"
#import "GORCycleManager.h"
#import "NSString+Utils.h"
#import "AppController.h"
#import "TextFieldTableViewCell.h"
#import "TextViewTableViewCell.h"
#import "ActionTableViewCell.h"
#import "AppStyle.h"

@interface OldShareViewController ()

@property ShareHeaderCell *headerCell;
@property TextFieldTableViewCell *titleCell;
@property TextViewTableViewCell *descriptionCell;
@property ActionTableViewCell *loginCell;
@property UITableViewCell *guidelinesCell;
@property UITableViewCell *categoryGameCell;
@property UITableViewCell *categoryToolCell;
@property UITableViewCell *categoryDemoCell;

@property (nonatomic) LCCPostCategory selectedCategory;
@property GORCycleManager *cycleManager;

@property (nonatomic) IBOutlet UIBarButtonItem *sendItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelItem;

@end

@implementation OldShareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    /*
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [AppStyle tableBackgroundColor];
    
    self.headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareHeaderCell"];
    self.headerCell.iconImageView.image = (self.project.iconData) ? [UIImage imageWithData:self.project.iconData] : [UIImage imageNamed:@"icon_project"];
    [self addCell:self.headerCell];
    
    self.loginCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareActionCell"];
    [self addCell:self.loginCell];
    
    [self setHeaderTitle:@"Program Title" section:1];
    
    self.titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextFieldCell"];
    self.titleCell.textField.placeholder = @"Title";
    self.titleCell.textField.text = self.project.name;
    [self addCell:self.titleCell];

    [self setHeaderTitle:@"Category" section:2];
    
    self.categoryGameCell = [self.tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
    self.categoryGameCell.textLabel.text = @"Game (or demo of game)";
    [self addCell:self.categoryGameCell];
    
    self.categoryToolCell = [self.tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
    self.categoryToolCell.textLabel.text = @"Tool";
    [self addCell:self.categoryToolCell];
    
    self.categoryDemoCell = [self.tableView dequeueReusableCellWithIdentifier:@"BasicCell"];
    self.categoryDemoCell.textLabel.text = @"Demo (graphics/sound examples)";
    [self addCell:self.categoryDemoCell];
    
    [self setHeaderTitle:@"Write a Description" section:3];
    
    self.descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"ShareTextViewCell"];
    if (self.project.programDescription)
    {
        self.descriptionCell.textView.text = self.project.programDescription;
    }
    [self addCell:self.descriptionCell];
    
    self.guidelinesCell = [self.tableView dequeueReusableCellWithIdentifier:@"GuidelinesCell"];
    [self addCell:self.guidelinesCell];
    
    [self updateLogin:nil];
    
    self.selectedCategory = (self.project.programType) ? self.project.programType.intValue : LCCPostCategoryUndefined;
    
    self.cycleManager = [[GORCycleManager alloc] initWithFields:@[self.titleCell.textField, self.descriptionCell.textView]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLogin:) name:CurrentUserChangeNotification object:nil];
     */
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUserChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    /*
    if (!self.project.iconData)
    {
        [self showAlertWithTitle:@"This program doesn't have an icon yet" message:@"Please start it once to create one!" block:^{
            [self onCancelTapped:nil];
        }];
    }
    else
    {
        NSError *error;
        [Compiler compileSourceCode:self.project.sourceCode error:&error];
        if (error)
        {
            [self showAlertWithTitle:@"This program has errors" message:@"Please fix them before posting!" block:^{
                [self onCancelTapped:nil];
            }];
        }
    }
     */
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    /*
    if (   self.descriptionCell.textView.text.length > 0
        && (!self.project.programDescription || ![self.descriptionCell.textView.text isEqualToString:self.project.programDescription]) )
    {
        self.project.programDescription = self.descriptionCell.textView.text;
    }
    if (self.selectedCategory != LCCPostTypeUndefined && self.selectedCategory != self.project.programType.intValue)
    {
        self.project.programType = @(self.selectedCategory);
    }
    [[ModelManager sharedManager] saveContext];
     */
}

- (void)setSelectedCategory:(LCCPostCategory)selectedCategory
{
    _selectedCategory = selectedCategory;
    self.categoryGameCell.accessoryType = (selectedCategory == LCCPostCategoryGame) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.categoryToolCell.accessoryType = (selectedCategory == LCCPostCategoryTool) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.categoryDemoCell.accessoryType = (selectedCategory == LCCPostCategoryDemo) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)updateLogin:(NSNotification *)notification
{
    LCCUser *user = [CommunityModel sharedInstance].currentUser;
    if (user)
    {
        self.loginCell.textLabel.text = [NSString stringWithFormat:@"%@ (Tap to log out)", user.username];
    }
    else
    {
        self.loginCell.textLabel.text = @"Log in / Register";
    }
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.view endEditing:YES];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSendTapped:(id)sender
{
    [self.view endEditing:YES];
    
    if (![CommunityModel sharedInstance].currentUser)
    {
        CommLogInViewController *vc = [CommLogInViewController create];
        [self presentInNavigationViewController:vc];
    }
    else if (self.selectedCategory == LCCPostCategoryUndefined)
    {
        [self showAlertWithTitle:@"Please select a category!" message:nil block:nil];
    }
    else if (self.titleCell.textField.text.length == 0 || self.descriptionCell.textView.text.length == 0)
    {
        [self showAlertWithTitle:@"Please fill out all required fields!" message:nil block:nil];
    }
    else
    {
        [self send];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.loginCell)
    {
        if ([CommunityModel sharedInstance].currentUser)
        {
            [[CommunityModel sharedInstance] logOut];
        }
        else
        {
            CommLogInViewController *vc = [CommLogInViewController create];
            [self presentInNavigationViewController:vc];
        }
    }
    else if (cell == self.categoryGameCell)
    {
        self.selectedCategory = LCCPostCategoryGame;
    }
    else if (cell == self.categoryToolCell)
    {
        self.selectedCategory = LCCPostCategoryTool;
    }
    else if (cell == self.categoryDemoCell)
    {
        self.selectedCategory = LCCPostCategoryDemo;
    }
    else if (cell == self.guidelinesCell)
    {
        [self showGuidelines];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)send
{
    [self isBusy:YES];
    /*

    NSString *title = self.titleCell.textField.text;
    NSString *description = self.descriptionCell.textView.text;
    
    NSString *fileTitle = [title stringByReplacingOccurrencesOfString:@"[^a-zA-Z_0-9]+" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, title.length)];
    if (fileTitle.length > 30)
    {
        fileTitle = [fileTitle substringToIndex:30];
    }
    // icon file
    [[CommunityModel sharedInstance] uploadFileWithName:[NSString stringWithFormat:@"%@.png", fileTitle] data:self.project.iconData completion:^(NSURL *url, NSError *error) {
        
        if (url)
        {
            NSURL *iconFileURL = url;
            
            // program file
            NSData *fileData = [self.project.sourceCode dataUsingEncoding:NSUTF8StringEncoding];
            
            [[CommunityModel sharedInstance] uploadFileWithName:[NSString stringWithFormat:@"%@.txt", fileTitle] data:fileData completion:^(NSURL *url, NSError *error) {
            
                if (url)
                {
                    NSURL *programFileURL = url;
                    
                    // post
                    LCCPost *post = [[LCCPost alloc] init];
                    post.type = LCCPostTypeProgram;
                    post.title = title;
                    post.detail = description;
                    post.program = programFileURL;
                    post.image = iconFileURL;
                    post.category = self.selectedCategory;
                    
                    NSString *route = [NSString stringWithFormat:@"/users/%@/posts", [CommunityModel sharedInstance].currentUser.objectId];
                    NSDictionary *params = [post dirtyDictionary];
                    
                    [[CommunityModel sharedInstance].sessionManager POST:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                        
                        [post updateWithDictionary:responseObject[@"post"]];
                        [post resetDirty];
                        
                        [[CommunityModel sharedInstance] clearCache];
                        
                        self.project.postId = post.objectId;
                        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                        
                    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                        
                        [self showSendError:error];
                        
                    }];
                }
                else
                {
                    [self showSendError:error];
                }
                
            }];
            
        }
        else
        {
            [self showSendError:error];
        }
        
    }];
     */
}

- (void)showSendError:(NSError *)error
{
    [self isBusy:NO];
    [[CommunityModel sharedInstance] handleAPIError:error title:@"Could not send program" viewController:self];
}

- (void)showGuidelines
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"CommGuidelinesView"];
    [self.navigationController pushViewController:vc animated:YES];
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

@implementation ShareHeaderCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.text = @"Post this program to your community profile! If we like it, we will feature it in the LowRes Coder news.";
    CALayer *layer = self.iconImageView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 3;
    layer.borderWidth = 0.5;
    layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
}

@end
