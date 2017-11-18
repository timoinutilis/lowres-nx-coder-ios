//
//  CommEditUserViewController.m
//  Pixels
//
//  Created by Timo Kloss on 1/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommEditUserViewController.h"
#import "CommunityModel.h"
#import "UIViewController+LowResCoder.h"
#import "GORCycleManager.h"
#import "AppStyle.h"

@interface CommEditUserViewController ()

@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property CommEditUserInputCell *usernameCell;
@property CommEditUserInputCell *emailCell;
@property CommEditUserInputCell *passwordCell;
@property CommEditUserInputCell *passwordVerifyCell;
@property CommEditUserTextViewCell *aboutCell;
@property LCCUser *user;
@property GORCycleManager *cycleManager;

@end

@implementation CommEditUserViewController

+ (CommEditUserViewController *)create
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    CommEditUserViewController *vc = (CommEditUserViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CommEditUserView"];
    return vc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [AppStyle tableBackgroundColor];
    
    [self setHeaderTitle:@"Account" section:0];
    self.usernameCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommEditUserInputCell"];
    self.usernameCell.textField.placeholder = @"Username";
    self.usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    [self addCell:self.usernameCell];

    self.emailCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommEditUserInputCell"];
    self.emailCell.textField.placeholder = @"E-Mail (optional)";
    self.emailCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
    [self addCell:self.emailCell];
    [self setFooterTitle:@"The e-mail address is never shown to other users." section:0];

    [self setHeaderTitle:@"Change Password" section:1];
    self.passwordCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommEditUserInputCell"];
    self.passwordCell.textField.placeholder = @"New password";
    self.passwordCell.textField.secureTextEntry = YES;
    [self addCell:self.passwordCell];

    self.passwordVerifyCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommEditUserInputCell"];
    self.passwordVerifyCell.textField.placeholder = @"Repeat new password";
    self.passwordVerifyCell.textField.secureTextEntry = YES;
    [self addCell:self.passwordVerifyCell];
    
    [self setHeaderTitle:@"Write something about you" section:2];
    self.aboutCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommEditUserTextViewCell"];
    [self addCell:self.aboutCell];
    
    self.cycleManager = [[GORCycleManager alloc] initWithFields:@[self.usernameCell.textField, self.emailCell.textField, self.passwordCell.textField, self.passwordVerifyCell.textField, self.aboutCell.textView]];
    
    // set user data
    self.user = [CommunityModel sharedInstance].currentUser;
    self.usernameCell.textField.text = self.user.username;
    self.emailCell.textField.text = self.user.email;
    self.aboutCell.textView.text = self.user.about;
}

- (IBAction)onSaveTapped:(id)sender
{
    [self.view endEditing:YES];
    
    NSString *username = self.usernameCell.textField.text;
    NSString *email = self.emailCell.textField.text;
    NSString *password = self.passwordCell.textField.text;
    NSString *passwordVerify = self.passwordVerifyCell.textField.text;
    
    if (username.length < 4)
    {
        [self showAlertWithTitle:(username.length == 0 ? @"Please enter a username!" : @"Please enter a longer username!") message:nil block:^{
            [self.usernameCell.textField becomeFirstResponder];
        }];
        return;
    }
    if (password.length > 0)
    {
        if (password.length < 4)
        {
            [self showAlertWithTitle:@"Please enter a longer password!" message:nil block:^{
                [self.passwordCell.textField becomeFirstResponder];
            }];
            return;
        }
        if (passwordVerify.length == 0)
        {
            [self showAlertWithTitle:@"Please repeat your password!" message:nil block:^{
                [self.passwordVerifyCell.textField becomeFirstResponder];
            }];
            return;
        }
        if (![password isEqualToString:passwordVerify])
        {
            [self showAlertWithTitle:@"Passwords do not match" message:nil block:^{
                self.passwordCell.textField.text = @"";
                self.passwordVerifyCell.textField.text = @"";
                [self.passwordCell.textField becomeFirstResponder];
            }];
            return;
        }
    }
    
    // update user data
    self.user.username = username;
    self.user.email = email;
    self.user.about = self.aboutCell.textView.text;
    if (password.length > 0)
    {
        self.user.password = password;
    }
    
    [self setBusy:YES];
    
    NSString *route = [NSString stringWithFormat:@"/users/%@", self.user.objectId];
    NSDictionary *params = [self.user dirtyDictionary];
    
    [[CommunityModel sharedInstance].sessionManager PUT:route parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

        [self.user resetDirty];
        [[CommunityModel sharedInstance] clearCache];
        
        // save name for log-in view
        NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
        [storage setObject:username forKey:UserDefaultsLogInKey];
        
        [[CommunityModel sharedInstance] onUserDataChanged];
        
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

        [self setBusy:NO];
        [[CommunityModel sharedInstance] handleAPIError:error title:@"Could not save changes" viewController:self];

    }];
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setBusy:(BOOL)busy
{
    self.navigationItem.leftBarButtonItem.enabled = !busy;
    if (busy)
    {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
        [activity startAnimating];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = self.saveButton;
    }
}


@end

@implementation CommEditUserInputCell
@end

@implementation CommEditUserTextViewCell
@end
